---
user-invocable: true
description: "[タスク実行] 3. TASK実行"
---

# [タスク実行] 3. TASK実行 (引数:Issue番号)

## Issue番号: $ARGUMENTS

指定されたIssueに従って実装を行います。
**RDD準拠**が満たされているか、**変更要求(ADR-lite)が承認済み**かを着手前に確認します。
進捗と完了報告は **Issueコメント** で記録し、完了時は **Issueをclose** します。

## 共通前提（参照）
- 実装規約・口調・出力規約・TDD・Docコメント等は `CLAUDE.md` に従う。
- `doc/rdd.md` を読み、該当する `.claude/skills/*` を適用して判断軸を揃える（例: `architecture-expert` / `developer-specialist` / `security-expert`）。
- 詳細運用（サンプル運用/依存評価補助/ADR-lite）は `doc/ai_guidelines.md` を参照。

---

## GitHub連携の前提

### 必要な権限
以下の `gh` コマンドが実行可能であること：
- `gh issue view` / `gh issue comment` / `gh issue close`

### Issue内容取得
```bash
gh issue view {ISSUE_NUMBER} --json title,body,milestone,labels
```

---

## 実行プロセス

### 1. プレチェック
```bash
# Issue内容を取得して確認
gh issue view {ISSUE_NUMBER}
```
- RDD参照セクションの存在
- 技術スタックがRDDと一致
- 逸脱がある場合は **変更要求(ADR-lite)の承認済み** を確認

### 2. 着手コメント
```bash
gh issue comment {ISSUE_NUMBER} --body "🚀 着手開始

## 実行計画
- [ ] {ステップ1}
- [ ] {ステップ2}
- [ ] {ステップ3}
"
```

### 3. 深く考える
- 要件をToDoに分解（最小ステップ）
- 既存パターン再利用と重複回避を最優先に、差分最小の計画を立てる

### 4. 実装（TDD厳守）
- `CLAUDE.md` の規約に従い、RED → GREEN → REFACTOR で段階的に進める

### 5. 検証
```bash
pnpm lint --fix && pnpm type-check
pnpm test
```
- 失敗時の切り分け（最小サンプル運用等）は `CLAUDE.md` の方針に従う

### 6. 進捗コメント（適宜）
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

### 7. 完了報告 & close
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
- [ ] サンプルは**フレームワークに適した `samples/`** にあり、適切命名・CI/計測から除外されている
- [ ] 解決後にサンプルを削除済み、または削除PRが用意されている
- [ ] 技術的負債が記録され、次スプリントに回されている
- [ ] **Issueに完了コメントを投稿済み**
- [ ] **Issueをclose済み**

---

## 自己評価
成功自信度 (1-10) ＋ 一言理由
