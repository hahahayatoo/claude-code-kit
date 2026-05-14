---
name: discuss
description: レビューPASS後、設計判断についてユーザーとディスカッションする。/reviewの後、/commitの前に使用。
agent: discuss-agent
allowed-tools: Task
---

# 設計ディスカッション

レビュー通過後、コミット前に設計判断についてユーザーと対話的に議論します。

## 実行方法

このスキルは `discuss-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "Design discussion agent"
- prompt: .claude/agents/discuss-agent.md の内容を使用
```

## ディスカッション結果による次のステップ

| 結果 | 次のステップ |
|------|-------------|
| NEEDS_CHANGE | `/implement` で修正後、`/test` → `/review` |
| NO_CHANGE | `/commit` でコミット |
