# claude-setup

Claude Code にTDD駆動開発ワークフローを導入するCLIツール。

エージェント・スキルを `~/.claude/` にインストールし、
`claude-setup init` で任意のプロジェクトにワークフローを適用できる。

## セットアップ

```bash
git clone <this-repo> ~/claude-agent
export PATH="$HOME/claude-agent/bin:$PATH"  # .bashrc / .zshrc に追加
```

## 使い方

### 1. インストール（初回のみ）

```bash
# コアコンポーネント（エージェント + スキル + CLAUDE.md）
claude-setup install

# DB ワークフローも含める場合
claude-setup install --with-db
```

### 2. プロジェクトへの適用

```bash
claude-setup init /path/to/project

# DB ワークフロー含む
claude-setup init /path/to/project --with-db
```

### 3. 更新

```bash
# このリポジトリでエージェント等を編集後
claude-setup update

# ローカル変更を上書き
claude-setup update --force

# 削除されたエージェント/スキルをクリーンアップ
claude-setup update --cleanup

# DB コンポーネントの追加・削除
claude-setup update --add-db
claude-setup update --remove-db
```

#### このリポジトリを修正したとき、適用済み環境で何をすればよいか

修正内容に応じて、以下のコマンドを実行してください。

| 修正したファイル | 必要な操作 | 備考 |
|---|---|---|
| `.claude/agents/*.md` の **追加・編集** | `claude-setup update` | `~/.claude/agents/` に反映 |
| `.claude/agents/*.md` の **削除・改名** | `claude-setup update --cleanup` | 旧ファイルを `~/.claude/agents/` から削除 |
| `.claude/skills/*/SKILL.md` の **追加・編集** | `claude-setup update` | `~/.claude/skills/` に反映 |
| `.claude/skills/*/` の **削除・改名** | `claude-setup update --cleanup` | 旧ディレクトリを `~/.claude/skills/` から削除 |
| `templates/user/CLAUDE.md.tmpl` | `claude-setup update` | `~/.claude/CLAUDE.md` に反映 |
| `templates/project/CLAUDE.md.tmpl`（Tier 3） | 各プロジェクトで `claude-setup init --force` | プロジェクト直下の `CLAUDE.md` を再生成（ローカル変更は上書きされる） |
| `templates/project/workflow-CLAUDE.md.tmpl`（Tier 2） | 各プロジェクトで `claude-setup init --force` | `<project>/.claude/CLAUDE.md` を再生成 |
| `templates/project/settings.json.tmpl` | 各プロジェクトで `claude-setup init --force` | `<project>/.claude/settings.json` を再生成 |
| `bin/claude-setup` | 何もしなくて OK | 次回コマンド実行時に新しいバージョンが効く |

注意点:

- `claude-setup update` はローカル変更（`~/.claude/` 配下で手で編集したファイル）を **skip** します。上書きしたい場合は `--force` を付けてください。
- `claude-setup init --force` はローカルカスタマイズを上書きします。プロジェクトテンプレートを編集している場合は、事前に差分を確認してマージしてください。
- 何が変わるか確認したい場合は、まず `git log --oneline` でこのリポジトリの変更履歴を確認することを推奨します。

### 4. 状態確認

```bash
claude-setup status
```

## ワークフロー

`install` + `init` 後のプロジェクトで Claude Code を起動すると、以下のスキルが使える:

```
/hear         要件ヒアリング（コードベース調査+補足コンテキストを handoff.md に出力）
/architect    アーキテクチャ設計・実装計画（言語・技術スタック決定を含む）
/implement    TDD実装（Red → Green → Refactor）
/test         テスト実行
/code-review  コードレビュー
/commit       変更コミット
/plan-check   計画と実装の整合性チェック（複数イテレーション時）
```

DB ワークフロー（`--with-db` 時）:

```
/db-schema   PostgreSQL スキーマ設計
/db-review   スキーマレビュー
```

## 言語・テストフレームワーク

言語とテストフレームワークは `/architect` 実行時に決定される。
既存コードベースから自動検出するか、ユーザーに確認して確定し、
`docs/context/current-state.json` に記録される。

## 構成

```
claude-agent/
├── .claude/
│   ├── agents/          # エージェント定義（ソースオブトゥルース）
│   ├── skills/          # スキル定義
│   └── hooks/           # フックスクリプト
├── bin/
│   └── claude-setup     # CLI 本体
├── templates/
│   ├── user/            # ユーザーレベル テンプレート
│   └── project/         # プロジェクトレベル テンプレート
└── tests/
    └── test_claude_setup.bats
```

### CLAUDE.md の3階層構成

`claude-setup` は CLAUDE.md を3つの階層に分けて管理する:

| 階層 | ファイル | 内容 | 管理 |
|------|---------|------|------|
| Tier 1 | `~/.claude/CLAUDE.md` | 回答言語・コメント言語・planモード方針 | `install` |
| Tier 2 | `<project>/.claude/CLAUDE.md` | ワークフロー順序・コード生成ポリシー・DB設定 | `init` |
| Tier 3 | `<project>/CLAUDE.md` | TDD原則・コミット規約・禁止事項・プロジェクト固有ルール | `init` |

- **Tier 1**: ユーザー全体に適用される個人設定
- **Tier 2**: スキル/ワークフローに依存する知識（スキルがない環境では不要）
- **Tier 3**: どの環境でも有効なプロジェクト固有のルール（git commit 推奨）

### `install` で `~/.claude/` に配置されるもの

```
~/.claude/
├── CLAUDE.md    # Tier 1: ユーザー全体の方針
├── agents/      # 全プロジェクト共通のエージェント
└── skills/      # 全プロジェクト共通のスキル
```

### `init` でプロジェクトに生成されるもの

```
<project>/
├── .claude/
│   ├── settings.json   # 権限設定
│   └── CLAUDE.md       # Tier 2: ワークフロー知識
├── CLAUDE.md            # Tier 3: プロジェクトルール
└── docs/
    ├── context/         # 要件・コンテキスト情報
    └── plans/           # 実装計画
```

## カスタマイズ

プロジェクトごとに自由に編集できる:

| ファイル | カスタマイズ例 |
|----------|--------------|
| `CLAUDE.md` | コーディング規約、プロジェクト固有ルール追加 |
| `.claude/CLAUDE.md` | ワークフロー順序の変更、DB設定のパス変更 |
| `.claude/settings.json` | 権限追加 |

プロジェクトレベルの `.claude/agents/` に同名ファイルを置くと、
ユーザーレベル（`~/.claude/agents/`）より優先される。

## テスト

```bash
bats tests/test_claude_setup.bats
```
