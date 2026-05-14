# Claude Code 環境構築プロジェクト

## このリポジトリについて

Claude Code のワークフロー設定（エージェント、スキル、フック）を管理し、
`claude-setup` コマンドで任意のプロジェクトに適用するためのリポジトリ。

## ディレクトリ構成

| ディレクトリ | 用途 |
|-------------|------|
| `.claude/agents/` | エージェント定義（ソースオブトゥルース） |
| `.claude/skills/` | スキル定義（ソースオブトゥルース） |
| `.claude/hooks/` | フックスクリプト |
| `bin/` | CLI ツール（claude-setup） |
| `templates/` | プロジェクト初期化用テンプレート |
| `tests/` | CLI ツールのテスト |
| `docs/` | 設計ドキュメント |

## ワークフロー

### エージェント・スキルの編集
1. `.claude/agents/` または `.claude/skills/` のファイルを編集
2. `claude-setup update` で ~/.claude/ に反映

### 新プロジェクトへの適用
```
claude-setup init /path/to/project
```

言語・テストフレームワークは `/architect` 実行時に自動検出またはユーザー指定で決定される。

### このリポジトリの開発方針

- エージェント・スキル・テンプレート等の修正は、TDDワークフロー（`/implement`）を使わず直接編集してよい
- テストは必要に応じて書く（必須ではない）
- `/hear` → `/architect` → `/implement` のフルワークフローは適用先プロジェクト向けの機能であり、このリポジトリ自体には不要

## コミットメッセージ規約

```
<type>: <subject>

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Type

- `feat`: 新機能
- `fix`: バグ修正
- `test`: テスト追加・修正
- `refactor`: リファクタリング
- `docs`: ドキュメント

## コーディング規約

- **コード内のコメント・docstring は必ず日本語で記述する**
- 変数名・関数名・クラス名は英語でよい
- エラーメッセージやログ出力は英語でもよい

## 禁止事項

- `.env`ファイルの編集・コミット
- シークレット情報のハードコード
