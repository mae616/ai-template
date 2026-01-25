---
user-invocable: true
description: "[バグ対応] 4. 修正実行を恒久対応・段階実施＋無効時ロールバックでする"
---

# [バグ対応] 4. 修正実行を恒久対応・段階実施＋無効時ロールバックでする (引数:Issue番号)

## 入力
- `$ARGUMENTS` : 対象のバグIssue番号
  - 例: `#123` または `123`

---

## 🎯 目的
- `$ARGUMENTS` のIssueに記載された **「修正策（候補一覧）」** を上から順に実行する
- **恒久対応のみ** を実施（暫定対応はスキップ、または恒久案に置換）
- 各修正の効果を検証し、**効果なしの場合は修正前の状態へロールバック**
- 修正完了後は **Pull Request** を作成し、`Fixes #{ISSUE_NUMBER}` でIssueに紐づける
- マージ時にIssueが自動closeされる

---

## GitHub連携の前提

### 必要な権限
以下の `gh` コマンドが実行可能であること：
- `gh issue view` / `gh issue comment`
- `gh pr create` / `gh pr view`

---

## 前提ポリシー（安全運用）
- **安全第一**：本番影響のある操作は別環境で実施、シークレット露出禁止、最小権限
- **検証必須**：修正ごとに再現テスト／自動テスト／メトリクスで効果判定
- **可逆性**：修正ごとにコミットを分離、**無効時は即 `git revert`**
- **恒久性**：一時ファイル削除やタイミング依存などの **暫定策は採用しない**

---

## 実行手順

### 1. Issue内容を取得
```bash
gh issue view {ISSUE_NUMBER} --json title,body,labels
```
以下を抽出：
- 問題の概要 / 再現手順 / 期待する動作（理想状態） / ギャップ
- **修正策（候補一覧）**（仮説ごとの案）
- 参考資料（出典）

### 2. 作業ブランチ作成
```bash
git checkout -b fix/{ISSUE_NUMBER}-{short-description}
```

### 3. 着手コメント（Issueに）
```bash
gh issue comment {ISSUE_NUMBER} --body "🚀 修正着手

ブランチ: \`fix/{ISSUE_NUMBER}-{short-description}\`

## 実行計画
- [ ] 修正案1を適用
- [ ] 検証（テスト実行）
- [ ] 効果確認
"
```

### 4. 修正案の逐次実行ループ
各案ごとに以下を行う：

a. **変更を最小コミットで適用**（1案＝1コミット）

b. **検証**
```bash
pnpm lint --fix && pnpm type-check
pnpm test
```
再現手順・自動テスト・メトリクスで効果判定

c. **判定**
- **効果あり** → コミットを保持、次のステップへ
- **効果なし** → `git revert` でロールバック、次の修正案へ

### 5. PR作成
```bash
gh pr create \
  --title "fix: {問題の要約}" \
  --body "$(cat <<'EOF'
## Summary
- {修正内容の要約}

## Related Issue
Fixes #{ISSUE_NUMBER}

## Changes
- {変更点1}
- {変更点2}

## Test Plan
- [ ] 再現手順で問題が解消されることを確認
- [ ] 既存テストがパスすることを確認
- [ ] {追加の検証項目}

## Rollback
問題があれば `git revert` で戻せます

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### 6. Issueに完了コメント
```bash
gh issue comment {ISSUE_NUMBER} --body "✅ 修正完了

## 結果サマリ
- **採用した修正案**: {修正案名}
- **検証結果**: lint/type/test すべてPASS

## Pull Request
{PR_URL}

マージ後、このIssueは自動でcloseされます。
"
```

---

## 出力（GitHub）
- **Pull Request**: `Fixes #{ISSUE_NUMBER}` でIssueに紐づけ
- **Issueコメント**: 修正完了報告とPRリンク
- **Issue**: PRマージ時に自動close

---

## 効果判定ガイド
- **成功基準**（例）：
  - 再現手順で **失敗が再現しない**／エラーログが消失
  - 該当ユニット/E2Eテストが **安定合格**（n回連続）
  - 関連メトリクス（エラーレート/レイテンシ/メモリ等）が **閾値内**
- **失敗基準**：
  - 事象が継続／別の回帰を誘発／メトリクス悪化／副作用が許容外

---

## 品質チェックリスト
- [ ] 各修正案を **個別コミット** で適用し、可逆性を担保している
- [ ] **検証条件**（再現ケース・成功基準・メトリクス）が明確
- [ ] 効果なしの修正は **即ロールバック**
- [ ] 暫定対応を避け、**恒久対応のみ** 実施している
- [ ] **PRが作成され、Issueに紐づいている**（`Fixes #...`）
- [ ] Issueに完了コメントを投稿済み

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {短く理由を記載。例: 「再現テストで5回連続合格・関連メトリクスも安定」}
