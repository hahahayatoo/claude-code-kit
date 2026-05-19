---
name: db-review
description: 既存RDBMSスキーマをレビューし、パフォーマンス・設計品質の改善提案を行う（PostgreSQL/MySQL/SQLite対応）。
agent: db-review-agent
allowed-tools: Task
---

# RDBMSスキーマレビュー

既存の RDBMS スキーマ（PostgreSQL / MySQL / SQLite）をレビューし、改善提案を行います。

対象 RDBMS は CLAUDE.md / requirements.md の記述、または DDL の特徴から自動判定されます。判定不可の場合は確認します。

## 実行方法

このスキルは `db-review-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "RDBMS schema review agent"
- prompt: .claude/agents/db-review-agent.md の内容を使用
```

## 次のステップ

| 結果 | 次のステップ |
|------|-------------|
| 優秀/良好 | マイグレーション生成（プロジェクトのツールに従う） |
| 要改善 | スキーマ修正後、再レビュー |
| 要再設計 | `/architect` でスキーマ設計を再検討 |
