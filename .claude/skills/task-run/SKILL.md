---
user-invocable: true
description: "[タスク] 3. Issue実行 + 進捗同期"
---

# [タスク] 3. Issue実行 + 進捗同期

## 入力: $ARGUMENTS
- Issue番号（例: `#123` または `123`）
- 省略時: 実行可能なIssue（依存解決済み）を一覧表示して選択

---

## 🎯 目的
- 指定されたIssue（または選択したIssue）に従って実装を行う
- **組み込みTask** と **GitHub Issue** の進捗を同期する
- 完了時に両方を更新（Task: completed、Issue: close）

---

## 共通前提（参照）
- 実装規約・口調・TDD・Docコメント等は `CLAUDE.md` に従う
- `doc/rdd.md` を読み、該当する `.claude/skills/*` を適用
- 詳細運用は `doc/ai_guidelines.md` を参照

---

## 実行手順

### 1. Issue選択（引数省略時）
```
📋 実行可能なIssue（依存解決済み）

┌────┬─────────────────────┬──────────┬─────────────┬─────────────┐
│ #  │ Title               │ Issue    │ Task Status │ blockedBy   │
├────┼─────────────────────┼──────────┼─────────────┼─────────────┤
│ 1  │ API設計             │ #126     │ pending     │ なし ✅     │
│ 2  │ ユーザー認証実装     │ #123     │ pending     │ なし ✅     │
│ -  │ ログイン画面作成     │ #124     │ pending     │ #123 ⏳     │
└────┴─────────────────────┴──────────┴─────────────┴─────────────┘

→ どのIssueを実行する？ [番号を入力]
```

### 2. プレチェック
```bash
# Issue内容を取得して確認
gh issue view {ISSUE_NUMBER}
```
- `ready-for-dev` ラベルがあるか
- RDD参照セクションの存在
- 変更要求がある場合は **承認済み** か確認
- 組み込みTaskの blockedBy が空か確認

### 3. 着手（組み込みTask + Issue同期）

**組み込みTask更新:**
```
TaskUpdate:
  taskId: "{task-id}"  # metadata.issueNumber で特定
  status: "in_progress"
```

**Issueコメント（⚠️ 確認あり）:**
```bash
gh issue comment {ISSUE_NUMBER} --body "🚀 着手開始

## 実行計画
- [ ] {ステップ1}
- [ ] {ステップ2}
- [ ] {ステップ3}
"
```

### 4. 実装（TDD厳守）
- `CLAUDE.md` の規約に従い、RED → GREEN → REFACTOR で段階的に進める
- 要件をToDoに分解（最小ステップ）
- 既存パターン再利用と重複回避を最優先

### 5. 検証
```bash
pnpm lint --fix && pnpm type-check
pnpm test
```
- 失敗時の切り分け（最小サンプル運用等）は `CLAUDE.md` の方針に従う

### 6. 進捗報告（適宜）
```bash
gh issue comment {ISSUE_NUMBER} --body "📝 進捗報告

## 完了
- [x] {完了したステップ}

## 次のステップ
- [ ] {残りのステップ}

## メモ
{気づいた点や注意点}
"
```

### 7. 完了（組み込みTask + Issue同期）

**組み込みTask更新:**
```
TaskUpdate:
  taskId: "{task-id}"
  status: "completed"
```

**Issueコメント + close（⚠️ 確認あり）:**
```bash
gh issue comment {ISSUE_NUMBER} --body "✅ TASK完了

## 結果サマリ
- **RDD整合**: OK（根拠: doc/rdd.md §...）
- **変更要求**: 無し / 有（承認済み）
- **検証結果**: lint/type/test すべてPASS

## 差分要約
- {主要変更1}
- {主要変更2}

## 次の一手
- {フォローアップ1}
- {フォローアップ2}
"

gh issue close {ISSUE_NUMBER}
```

---

## 失敗時のガイド

### RDD違反
```bash
gh issue comment {ISSUE_NUMBER} --body "⚠️ RDD違反検出

## 内容
{違反内容}

## 変更要求(ADR-lite)
{変更提案}

## ステータス
承認待ち（ユーザー確認後に再開）
"
```

### 制約で実現不能
```bash
gh issue comment {ISSUE_NUMBER} --body "🚫 実現不能

## 理由
{制約の内容}

## 代替案
1. {代替案1}: {影響}
2. {代替案2}: {影響}

## ロールバック方法
{戻し方}
"
```

---

## 品質チェックリスト
- [ ] RDD準拠（スタック/制約に一致）
- [ ] Docコメント（JSDoc/Docstring）が全関数・クラスにある
- [ ] 重複コードを作らず既存パターンを再利用
- [ ] コメントで**ドメイン意図**と**決定理由**を明記
- [ ] 検証ゲート（lint/type/test）がPASS
- [ ] 必要なら最小サンプルで検証済み（削除可注記）
- [ ] 技術的負債が記録され、次スプリントに回されている
- [ ] **組み込みTask が completed に更新済み**
- [ ] **Issueに完了コメントを投稿済み**
- [ ] **Issueをclose済み**

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {短く理由を記載}
