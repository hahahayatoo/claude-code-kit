---
name: code-review
description: 6観点並列レビュー + Critical/Major への 3-lens 反証。/test の後、/commit の前に使用。
allowed-tools: Read, Grep, Glob, Bash, Task, Write
---

# コードレビュー（並列専門化 + 反証、worktree 隔離）

6 つの観点別専門エージェントを **worktree 隔離下で並列起動** し、Critical/Major の指摘を 3 並列 verifier で反証してから最終判定する。

**日時取得**: 生成日時等は `date -Iseconds` で取得する（フォーマット統一のため）。

## 全体フロー

```
Phase 1: 前処理（前提条件チェック、対象ファイル特定）
Phase 2: 6 観点並列レビュー（Agent × 6、worktree 隔離、return value）
Phase 3: 集約、Critical/Major 抽出
Phase 4: 反証（Critical/Major × verifier 3 並列、worktree 隔離、return value）
Phase 5: review-results.md 合成（main が書く）
Phase 6: 判定 + current-state.json 更新
```

## worktree 隔離と return value 化の背景

以前は各 review agent が `docs/context/review-results-<perspective>.md` に **Write** していた。しかし並列実行下で以下の問題があった:

- test-validity や verifier が動的検証（mutation testing、test runner）で **原本 workspace のファイルを変更**
- 他の並列 agent が読み取り中の状態を破壊、cross-contamination で racy な失敗
- 出力ファイル自体も同時書き込みの race リスク

**解決策**: 
- 各 review agent を `isolation: "worktree"` 付きで Task 起動 → 各 agent は独立した worktree コピーで作業
- **各 agent は return value のみで結果を返す**（ファイル書き込みなし）
- worktree は unchanged なら auto-remove（変更がある場合も終了時に破棄）
- 集約と review-results.md への書き込みは **main Claude が原本 workspace で 1 回だけ実施**

---

## Phase 1: 前処理

**メイン Claude が 1 回だけ実施する**（各サブエージェントで重複させない）。

### 1-0. 出力ディレクトリ準備

`mkdir -p docs/context` を Bash で実行。

### 1-1. 前提条件チェック

`docs/context/current-state.json` を Read し、以下を確認:

- `current_phase == "implement"` であること
- `last_test_result == "pass"` であること

**満たさない場合**は即座に中止し、以下のメッセージを出力:
> テストが通っていません。`/test` を実行して全テストがパスすることを確認してください。

### 1-2. 対象ファイル特定

1. `current-state.json` から `plan_file` を取得
2. plan_file を Read して実装対象を把握
3. `git diff --name-only HEAD` で変更ファイル一覧を取得
4. `src_dir` と `test_dir` 配下に絞り込む

**変更ファイルが 0 件の場合**は「レビュー対象の変更がありません」と出力して終了（Phase 2 以降スキップ）。

---

## Phase 2: 6 観点並列レビュー（worktree 隔離、return value）

**単一のアシスタントメッセージ内で 6 つの Task ツール呼び出しを並列送信する**（sequential で 1 つずつ呼ばない）。各 Task 呼び出しに **`isolation: "worktree"` を必ず指定する**。

| エージェント | 観点 |
|------|------|
| `quality-review-agent` | コード品質・可読性 |
| `security-review-agent` | セキュリティ |
| `design-review-agent` | 設計・アーキテクチャ |
| `coverage-review-agent` | テストカバレッジ |
| `test-validity-review-agent` | 無意味テスト検知 |
| `performance-review-agent` | パフォーマンス |

**各エージェントに以下を必ずプロンプトで渡す**:

- 対象ファイル一覧（Phase 1-2 で取得した絶対パスのリスト）
- 計画書パス（`plan_file`）

**出力先ファイルは渡さない**（各 agent は return value で結果を返す）。

### 各 agent の return value 形式

```
perspective: <name>
status: ok | no-findings | failed

## Good points   ← quality のみ（他観点にもあれば含む）
- ...

## Findings
### [Critical|Major|Minor] [file:line] [title]
- Confidence: [80-100]
- Content: ...
- (観点別追加フィールド: Category / Threat model / Uncovered / Pattern / Scaling 等)
- Fix: ...

### ...
```

- `perspective:` 行と `status:` 行を **必ず先頭2行** に取る
- `status: no-findings` の場合は Findings セクション省略
- `status: failed` の場合は `reason:` 行のみ

### 部分失敗の判定

Phase 2 完了時に、各 return value の `status:` 行を parse:
- **全 6 個が `ok` または `no-findings`** → Phase 3 に進む
- **1 個以上が `failed` または return が取得できない** → **PARTIAL モード**（後述の「部分失敗時の振る舞い」参照）

---

## Phase 3: 結果集約と Critical/Major 抽出

各 return value を parse し、指摘リストを構築:

1. 正規表現 `^perspective:\s*(\w[\w-]*)$` で観点名を抽出
2. 各 Finding の見出し `^### \[(Critical|Major|Minor)\] \[([^\]]+)\] (.+)$` から深刻度・ファイル位置・タイトルを抽出
3. Critical / Major のリストを反証対象として保持
4. Minor はそのまま保持（反証対象外）

Critical/Major が **0 件の場合** → Phase 4 スキップ、Phase 5 に直行。

---

## Phase 4: 反証（Critical/Major がある場合のみ、worktree 隔離）

各 Critical/Major 指摘に対して、`verifier-agent` を **3 並列** で起動する。**単一のアシスタントメッセージ内で複数の Task ツール呼び出しを並列送信する**（例: Critical/Major が 5 件なら 15 個の Task 呼び出しを 1 メッセージで送る）。**各 Task 呼び出しに `isolation: "worktree"` を必ず指定する**。

### プロンプトに渡す内容

verifier-agent 1 呼び出しにつき、1 つの指摘の以下を渡す:

- 深刻度
- ファイル:行番号
- 指摘内容
- 指摘の根拠
- 検出エージェント名
- Confidence score
- 対象ファイルパス（Read できる）

**3 並列は同一プロンプトで独立起動**する（他の verifier の判定は共有しない）。

### 応答の parse

各 verifier の return テキストから、正規表現 `^verdict:\s*(confirmed|refuted)$` にマッチする行を抽出する（verifier は前置き・後書きを禁止しているため、`verdict:` 行は 1 つだけ含まれる）。

抽出できなかった応答は `ERROR` 扱い。

### 多数決集計

各指摘について 3 verifier の verdict を集計:

- **2 人以上が `refuted`** → 「反証で取り下げ候補」に分類
- **それ以外**（3 confirmed, または 2 confirmed + 1 refuted）→ 「確定指摘」に分類
- **verifier が失敗した場合** → その verdict は `ERROR` 扱い（残り 2 人のうち 2 refuted で取り下げ、それ以外は確定）

### verify-log.md 書き出し（監査用、集約結果のみ）

**main Claude が原本 workspace の** `docs/context/verify-log.md` に以下の形式で書き出す（reasoning は含めない、シンプル）:

```markdown
# 反証ログ

生成日時: [ISO8601]

## 集約結果

| # | 深刻度 | ファイル:行 | 検出Agent | v1 | v2 | v3 | 多数決 |
|---|-------|-----------|----------|-----|-----|-----|-------|
| 1 | Critical | src/foo.py:42 | security | confirmed | refuted | confirmed | 確定 |
| 2 | Major | src/bar.py:15 | design | refuted | refuted | confirmed | 取り下げ候補 |
| 3 | Major | src/baz.py:8 | quality | confirmed | ERROR | confirmed | 確定 |
```

---

## Phase 5: review-results.md 合成（main Claude が書く）

**main Claude が原本 workspace の** `docs/context/review-results.md` を以下の 8 セクション構成で Write する。

### 合成ルール

- 各観点セクションには、その観点 agent の return value から得た指摘（Minor + 確定 Critical/Major）のみ含める
- **同一ファイル:行に複数観点から指摘があった場合は、それぞれの観点セクションに別々に記録する**（重複排除しない、判定件数もそのまま加算）
- **反証で取り下げ候補になった Critical/Major** は元の観点セクションから **削除** し、末尾の「反証で取り下げ候補」セクションに集約する
- **失敗した観点**（Phase 2 で `failed` or return 取得不能）は「未実施」と明記する（後述の PARTIAL）

### 出力フォーマット

```markdown
# コードレビュー結果

生成日時: [ISO8601]
対象ファイル: [Phase 1 で特定したファイル一覧]

## 1. サマリー

- 総合評価: [PASS | NEEDS_WORK | REJECT | PARTIAL]
- 指摘件数: Critical [N] / Major [N] / Minor [N]
- 反証で取り下げ: [N] 件
- 実施観点: [6 / 6] または「N 観点失敗」

## 2. コード品質・可読性
[quality-review-agent の指摘。0件なら「なし」]

## 3. セキュリティ
[security-review-agent の指摘。0件なら「なし」]

## 4. 設計・アーキテクチャ
[design-review-agent の指摘。0件なら「なし」]

## 5. テストカバレッジ
[coverage-review-agent の指摘。0件なら「なし」]

## 6. テスト有効性
[test-validity-review-agent の指摘。0件なら「なし」]

## 7. パフォーマンス
[performance-review-agent の指摘。0件なら「なし」]

## 8. 推奨事項
[全体所感、優先度の高い改善案 top 3 等]

## 反証で取り下げ候補

以下は Critical/Major として検出されたが、verifier の 3 並列多数決で反証されたため、
最終判定からは除外された。参考情報として記録。

### [元の深刻度] [ファイル:行番号] [タイトル]
- 元の検出エージェント: [quality-review-agent 等]
- 元の Confidence: [80-100]
- 反証結果: 3 verifier 中 [N] refuted
```

各指摘には以下を含める（各観点セクション内）:

```markdown
### [Critical|Major|Minor] [ファイル:行番号] [タイトル]
- Confidence: [80-100]
- 検出エージェント: [xxx-review-agent]
- 内容: [...]
- 根拠: [...]
- 修正案: [...]
```

---

## Phase 6: 判定と状態更新

### 判定ロジック（機械的）

**確定指摘のみ**（反証で取り下げられていない指摘）で件数集計:

| 条件 | 判定 |
|------|------|
| Critical: 1件以上 | **REJECT** |
| Critical: 0件 かつ (Major: 1件以上 または Minor: 4件以上) | **NEEDS_WORK** |
| Critical: 0件 / Major: 0件 / Minor: 3件以下 | **PASS** |

### current-state.json 更新

```json
{
  "current_phase": "review",
  "review_result": "PASS" | "NEEDS_WORK" | "REJECT",
  "has_critical_or_major": true | false,
  "review_results_file": "docs/context/review-results.md",
  "updated_at": "[ISO8601]"
}
```

- `has_critical_or_major`: 確定 Critical または Major が 1 件以上あれば `true`

---

## 部分失敗時の振る舞い（PARTIAL）

Phase 2 で 6 観点のうち **1 つ以上のエージェントが失敗** した場合（`status: failed` or return 取得不能）:

1. 成功した観点のみで Phase 3-5 を実施し、`review-results.md` を合成
2. `## 1. サマリー` の「実施観点」欄に「N 観点失敗: [失敗した観点名]」と明記
3. 該当セクションの本文は「未実施（エージェント失敗のため）」とする
4. **判定は行わない**（`review_result` を `"PARTIAL"` にする）
5. `current-state.json`:
   ```json
   {
     "current_phase": "review",
     "review_result": "PARTIAL",
     "has_critical_or_major": null,
     "review_results_file": "docs/context/review-results.md",
     "updated_at": "[ISO8601]"
   }
   ```
6. ユーザーに以下を提示:
   > レビューが部分的にしか完了していません（N 観点失敗: xxx, yyy）。
   > `/code-review` をリトライしますか？
   > それとも部分結果のまま次に進みますか？

**全観点が失敗した場合**:
- `review-results.md` は作成しない
- ユーザーに失敗理由を提示してリトライを促す

---

## エッジケース早見

| ケース | 対応 |
|-------|------|
| 前提条件不成立 | Phase 1-1 で中止、`/test` 案内 |
| 変更ファイル 0 件 | Phase 1-2 で終了通知 |
| 全観点で指摘 0 件 | Phase 4 スキップ、直接 PASS |
| 1 観点だけ失敗 | PARTIAL、判定保留 |
| 全観点失敗 | `review-results.md` 作らず、リトライ提示 |
| verifier 全失敗（1指摘に対し3人全滅） | 該当指摘は「確定」扱い（安全側） |
| 同一箇所に複数観点から指摘 | 別セクションに別々に記録、判定件数もそのまま加算 |

---

## レビュー結果による次のステップ

| 結果 | 次のステップ |
|------|-------------|
| PASS | `/commit` でコミット |
| NEEDS_WORK (has_critical_or_major: false) | `/implement` で Minor 修正後、`/test` → `/code-review` |
| NEEDS_WORK (has_critical_or_major: true) | `/architect` で修正計画作成後、`/implement` → `/test` → `/code-review` |
| REJECT | `/architect` で修正計画作成後、`/implement` → `/test` → `/code-review` |
| PARTIAL | ユーザー判断: `/code-review` リトライ、または部分結果のまま手動で対応 |
