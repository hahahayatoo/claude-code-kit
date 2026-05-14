---
name: implement
description: TDD（Red→Green→Refactor）で実装する。/architectの後、または/reviewの指摘修正に使用。
agent: tdd-agent
allowed-tools: Task
---

# TDD実装

Red → Green → Refactor のサイクルで実装します。

## 実行方法

このスキルは `tdd-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "TDD implementation agent"
- prompt: .claude/agents/tdd-agent.md の内容を使用
```

## 次のステップ

| モード | 次のステップ |
|--------|-------------|
| 新規実装 | `/test` → `/review` → `/commit` |
| 修正計画実行 | `/test` → `/review` → `/commit` |
| レビュー修正（Minor のみ） | `/test` → `/review` → `/commit` |
| Critical/Major 指摘あり | `/architect` を実行（修正計画モード） → `/implement` |
