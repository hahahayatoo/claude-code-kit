---
name: db-review
description: 既存PostgreSQLスキーマをレビューし、パフォーマンス・設計品質の改善提案を行う。
agent: db-review-agent
allowed-tools: Task
---

# PostgreSQLスキーマレビュー

既存のPostgreSQLスキーマをレビューし、改善提案を行います。

## 実行方法

このスキルは `db-review-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "PostgreSQL schema review agent"
- prompt: .claude/agents/db-review-agent.md の内容を使用
```

## 次のステップ

| 結果 | 次のステップ |
|------|-------------|
| 優秀/良好 | マイグレーション生成（プロジェクトのツールに従う） |
| 要改善 | `/db-schema` でスキーマ修正後、再レビュー |
| 要再設計 | `/db-schema` で再設計 |
