---
user-invocable: true
description: "1. Sprint計画（Milestone + Issue一括作成）"
---

# [タスク] 1. Sprint計画（Milestone + Issue一括作成）

## 入力: $ARGUMENTS
- コンテキストファイル（例: `doc/input/rdd.md`）

---

## 🎯 目的
- **doc/input/rdd.md** を根拠に、Sprint（Milestone）とタスク（Issue）を一括作成する
- 組み込みTask（TaskCreate）にも登録し、セッション中の並行・依存管理を可能にする
- GitHub と 組み込みTask の対応関係を維持する

---

## GitHub との対応関係

```
Repository = プロダクト
 └── Project = カンバンボード（任意）
      └── Milestone = Sprint
           └── Issue = タスク
```

---

## 実行手順

### 1. RDD読み込み・Sprint計画
```bash
# RDDを読み込み、Sprint単位でタスクを設計
```
- 目標/非目標、技術スタック、非機能要件を確認
- MVP優先でSprintを設計（1 Sprint = 1 Milestone）

### 2. Milestone作成（Sprint単位）
```bash
# Milestone存在確認
gh api repos/{owner}/{repo}/milestones --jq '.[] | select(.title=="sprint-1")'

# 存在しなければ作成（⚠️ 確認あり）
gh api repos/{owner}/{repo}/milestones -f title="sprint-1" -f description="Sprint 1: {目的}"
```

### 3. Issue一括作成
```bash
# 各タスクをIssueとして作成（⚠️ 確認あり）
gh issue create \
  --title "TASK-1: {タスク概要}" \
  --body "## 目的
{タスクの目的}

## RDD参照
- doc/input/rdd.md §{セクション}

## 検証ゲート
\`\`\`bash
pnpm lint --fix && pnpm type-check
pnpm test
\`\`\`

## 依存
- なし（または #XX）

## 決定理由
{なぜこのタスクが必要か}" \
  --milestone "sprint-1" \
  --label "task"
```

### 4. 組み込みTask登録
Issue作成後、組み込みTaskにも登録する：

```
TaskCreate:
  subject: "TASK-1: {タスク概要}"
  description: "{タスクの詳細}"
  activeForm: "{タスク概要}を実装中"
  metadata:
    issueNumber: 123
    milestone: "sprint-1"
```

### 5. 一覧表示
```
📋 Sprint: sprint-1

┌────┬─────────────────────┬──────────┬─────────────┐
│ #  │ Title               │ Issue    │ Status      │
├────┼─────────────────────┼──────────┼─────────────┤
│ 1  │ ユーザー認証実装     │ #123     │ pending     │
│ 2  │ ログイン画面作成     │ #124     │ pending     │
│ 3  │ API設計             │ #125     │ pending     │
└────┴─────────────────────┴──────────┴─────────────┘

次のステップ: /task-detail sprint-1
```

---

## 出力

### GitHub
- **Milestone**: `sprint-{n}`
- **Issues**: タスクごとに1 Issue（ラベル: `task`）

### 組み込みTask
- **TaskCreate**: 各Issueに対応するTask（metadata.issueNumber で紐づけ）

---

## 品質チェックリスト
- [ ] RDD/Architecture の整合性
- [ ] Milestone が正しく作成されている
- [ ] Issue に RDD参照・検証ゲートが含まれている
- [ ] 組み込みTask に issueNumber が設定されている
- [ ] 一覧表示で対応関係が確認できる

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {短く理由を記載}

---

## 次のステップ
```bash
/task-detail sprint-1  # Issue詳細化 + 依存関係設定
```
