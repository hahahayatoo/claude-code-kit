---
name: commit
description: テストが通っている場合のみ変更をコミットする。
agent: commit-agent
allowed-tools: Task
---

# コミット作成

テストが全て通っている場合のみ、変更をコミットします。

## 実行方法

このスキルは `commit-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "Bash"
- description: "Commit creation agent"
- prompt: .claude/agents/commit-agent.md の内容を使用
```

## エラー時

テストが失敗している場合、コミットはブロックされます。
`/implement` で修正してから再度 `/commit` を実行してください。
