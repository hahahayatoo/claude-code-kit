---
name: implement
description: TDD（Red→Green→Refactor）で実装する。/architectの後、または/code-reviewの指摘修正に使用。
agent: tdd-agent
allowed-tools: Task
---

# TDD実装

Red → Green → Refactor のサイクルで実装します。

## 実行方法

`tdd-agent` を Agent ツールで起動する。

## 次のステップ

| モード | 次のステップ |
|--------|-------------|
| 新規実装 | `/test` → `/code-review` → `/commit` |
| 修正計画実行 | `/test` → `/code-review` → `/commit` |
| レビュー修正（Minor のみ） | `/test` → `/code-review` → `/commit` |
| Critical/Major 指摘あり | `/architect` を実行（修正計画モード） → `/implement` |
