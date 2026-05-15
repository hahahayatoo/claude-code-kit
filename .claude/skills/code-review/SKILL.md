---
name: code-review
description: コード品質、セキュリティ、設計観点でコードレビューを行う。/test の後、/commit の前に使用。
agent: code-review-agent
allowed-tools: Task
---

# コードレビュー

テスト通過後、コミット前にコードレビューを行います。

## 実行方法

このスキルは `code-review-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "Code review agent"
- prompt: .claude/agents/code-review-agent.md の内容を使用
```

## レビュー結果による次のステップ

| 結果 | 次のステップ |
|------|-------------|
| PASS | `/commit` でコミット |
| NEEDS_WORK | `/implement` で修正後、`/test` → `/code-review` |
| REJECT | `/implement` で修正後、`/test` → `/code-review` |
