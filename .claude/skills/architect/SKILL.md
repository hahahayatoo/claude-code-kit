---
name: architect
description: 要件に基づいて実装計画・アーキテクチャ設計を行う。/hearの後、またはCritical/Majorのレビュー指摘時の修正計画作成に使用。
agent: planning-agent
allowed-tools: Task
---

# アーキテクチャ設計・実装計画

要件に基づいて詳細な実装計画を作成します。

## 実行方法

このスキルは `planning-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "Implementation planning agent"
- prompt: .claude/agents/planning-agent.md の内容を使用
```

## 次のステップ

### 新規計画モードの場合
計画が承認されたら、`/implement` でイテレーション1のTDD実装を開始してください。

#### イテレーション完了時のフロー

```
/implement → /test → /review → /commit
    ↓
（次のイテレーションがあれば）
    ↓
/plan-check → /implement へ
```

全イテレーション完了後、機能全体の統合テストを実施してください。

### 修正計画モードの場合
修正計画が作成されたら、`/implement` で修正計画に基づいた修正を実行してください。

```
/implement（修正計画実行モード） → /test → /review → /commit
```
