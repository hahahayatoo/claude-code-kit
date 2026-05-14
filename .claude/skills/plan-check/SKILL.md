---
name: plan-check
description: 計画書と実装コードの整合性をチェックする。/commitの後、次の/implementの前に使用。
agent: plan-check-agent
allowed-tools: Task
---

# 計画書整合性チェック

イテレーション完了後、次のイテレーションの計画書が実装済みコードと整合しているかを確認します。

## 実行方法

このスキルは `plan-check-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "Plan check agent"
- prompt: .claude/agents/plan-check-agent.md の内容を使用
```

## 実行タイミング

| タイミング | 推奨度 |
|-----------|-------|
| /commit の後、次の /implement の前 | 推奨 |
| その他のタイミング | 動作するが、意味があるのは commit 後のみ |

## 結果による次のステップ

| 結果 | 次のステップ |
|------|-------------|
| 齟齬なし | `/implement` で次のイテレーションを開始 |
| 齟齬あり・修正済み | `/implement` で次のイテレーションを開始 |
| 最終イテレーション完了後 | 不要（案内メッセージのみ） |
