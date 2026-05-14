---
name: db-schema
description: PostgreSQL新規スキーマを設計する。要件からDDLとドキュメントを生成。
agent: db-schema-agent
allowed-tools: Task
---

# PostgreSQLスキーマ設計

要件に基づいてPostgreSQLに最適化されたスキーマを設計します。

## 実行方法

このスキルは `db-schema-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "PostgreSQL schema design agent"
- prompt: .claude/agents/db-schema-agent.md の内容を使用
```

## 次のステップ

スキーマ設計が完了したら、`/db-review` でレビューを実施してください。
