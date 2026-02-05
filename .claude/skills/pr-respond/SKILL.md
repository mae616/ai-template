---
user-invocable: true
description: "[PR] レビューコメントに順次対応 - fetch→リスト→対応→コミットのループ"
---

# [PR] レビューコメント対応

## 入力: $ARGUMENTS
- PR番号（例: `#123` または `123`）
- 省略時: 現在のブランチに紐づくPRを自動検出

---

## 🎯 目的
- **PRのレビューコメント（他者からのフィードバック）に漏れなく対応する**
- セッション途中終了でも進捗が失われないよう、1件対応ごとにコミット
- 完了条件を明確にして「partially_achieved」を防ぐ

---

## 実行手順

### 1. PRとレビューコメント取得

**PR番号指定時:**
```bash
gh pr view {PR_NUMBER} --json number,title,state,reviews,comments
```

**省略時（現在ブランチから検出）:**
```bash
gh pr list --head $(git branch --show-current) --json number,title --jq '.[0]'
```

**レビューコメント一覧取得:**
```bash
gh api repos/{owner}/{repo}/pulls/{PR_NUMBER}/comments --jq '.[] | {id, path, line, body, user: .user.login}'
```

**PRレビュー（Approve/Request Changes等）取得:**
```bash
gh api repos/{owner}/{repo}/pulls/{PR_NUMBER}/reviews --jq '.[] | {id, state, body, user: .user.login}'
```

---

### 2. コメントをリスト化して提示

```markdown
## 📋 レビューコメント一覧

### PR: #{PR_NUMBER} - {title}

| # | ファイル | 行 | コメント | 投稿者 | 状態 |
|---|----------|-----|----------|--------|------|
| 1 | src/foo.ts | 23 | 「この変数名は...」 | reviewer1 | 🔴 未対応 |
| 2 | src/bar.ts | 45 | 「nullチェックが...」 | reviewer2 | 🔴 未対応 |
| 3 | - | - | 「全体的に良いですが...」 | reviewer1 | 🔴 未対応 |

**対応予定**: {count}件
```

> ⚠️ **ユーザー確認**: このリストで進めてよいか確認する

---

### 3. 1件ずつ対応ループ

各コメントに対して以下を繰り返す：

#### 3.1 対象コメントの詳細表示
```markdown
### 対応中: コメント #{n}/{total}

**ファイル**: {path}:{line}
**投稿者**: {user}
**コメント内容**:
> {body}

**該当コード** (前後5行):
```

#### 3.2 対応方針を提案
```markdown
**対応方針**:
- [ ] コード修正が必要
- [ ] コメント返信のみ（説明/質問への回答）
- [ ] 対応不要（既に解決済み/誤解）

**提案**: {具体的な修正内容または返信文}
```

> ⚠️ **ユーザー確認**: この対応でよいか確認する

#### 3.3 対応実行
```bash
# コード修正の場合
# Edit ツールで該当箇所を修正

# コメント返信の場合（任意）
gh api repos/{owner}/{repo}/pulls/{PR_NUMBER}/comments/{comment_id}/replies \
  -f body="{返信内容}"
```

#### 3.4 コミット（1件ごと）
```bash
git add -A
git commit -m "fix: PR#{PR_NUMBER} レビュー対応 - {対応内容の要約}

Co-Authored-By: {reviewer} (review feedback)
Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

#### 3.5 進捗更新
```markdown
### 進捗: {n}/{total} 完了

| # | 状態 | 対応内容 |
|---|------|----------|
| 1 | ✅ 完了 | 変数名を修正 |
| 2 | 🔄 対応中 | - |
| 3 | 🔴 未対応 | - |

**残り**: {remaining}件
```

---

### 4. 全件完了後

#### 4.1 push
```bash
git push
```

#### 4.2 完了サマリー
```markdown
## ✅ レビュー対応完了

### PR: #{PR_NUMBER} - {title}

| # | ファイル | 対応内容 | コミット |
|---|----------|----------|----------|
| 1 | src/foo.ts:23 | 変数名を修正 | abc1234 |
| 2 | src/bar.ts:45 | nullチェック追加 | def5678 |
| 3 | - | 返信のみ | - |

**対応件数**: {count}件
**コミット数**: {commits}件

### 次のアクション
- [ ] レビュアーに再レビュー依頼
- [ ] CIの確認
```

---

## 中断時の対応

セッションが中断されそうな場合：

```markdown
## ⏸️ 中断ポイント

**進捗**: {n}/{total}件完了
**最後のコミット**: {commit_hash}
**残りコメント**:
- #{n+1}: {path}:{line} - "{body_preview}..."

**再開用プロンプト**:
> /pr-respond {PR_NUMBER}
> 前回 #{n}まで完了。#{n+1}から再開してください。
```

---

## 注意事項

- **1件対応ごとにコミット**することで、途中終了でも進捗が失われない
- **コード修正 vs 返信のみ**を明確に区別する
- **レビュアーへの敬意**を忘れない（コメント返信時）
- 対応不要と判断した場合も、理由をコメントで返信する

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {短く理由を記載}
