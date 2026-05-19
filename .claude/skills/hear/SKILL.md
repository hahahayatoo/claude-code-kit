---
name: hear
description: ユーザーの要望を聞いて詳細な要件を整理する。新しい機能の実装前に使用。
agent: hearing-agent
allowed-tools: Task
---

# 要件ヒアリング

ユーザーの要望を聞き、詳細な要件を整理します。

## 実行方法

このスキルは `hearing-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "Requirements hearing agent"
- prompt: .claude/agents/hearing-agent.md の内容を使用
```

## 次のステップ

要件が整理できたら、`/architect` でアーキテクチャ設計・実装計画を作成してください。
DB スキーマ設計が必要な場合も `/architect` の中で設計します（DB 専用の設計スキルは持ちません）。
