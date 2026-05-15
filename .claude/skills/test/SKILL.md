---
name: test
description: テストを実行し、カバレッジ・網羅性を分析して結果を報告する。
allowed-tools: Task
---

# テスト分析・実行

プロジェクトのテストを実行し、包括的な分析結果を報告します。

## 実行方法

このスキルは `test-agent` を使用して実行されます。

```
Task ツール呼び出し:
- subagent_type: "general-purpose"
- description: "Test specialist agent"
- prompt: .claude/agents/test-agent.md の内容を使用
```

## 失敗時の対応

テストが失敗した場合：
1. 失敗したテストの詳細を表示
2. 原因を分析
3. `/implement` で修正を提案

## 次のステップ

全テストが通ったら、`/code-review` でコードレビューを実施してください。
