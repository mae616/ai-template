---
user-invocable: true
description: "進捗サマリーと再開用プロンプトを生成してsession-context.mdに保存する。作業の区切り、コンテキスト圧縮が近いとき、セッション終了時に使う。"
---

# [セッション] セッション終了

## 入力: $ARGUMENTS
- 省略可（現在のTaskListから自動取得）

---

## 🎯 目的
- **セッション終了時に進捗を保存**して、次回スムーズに再開できるようにする
- 未完了タスクと再開用プロンプトを生成する
- 中断しても何も失われない状態を作る

---

## 実行手順

### 1. 現在の状態確認

**TaskListの確認:**
```
TaskList を実行して現在のタスク状態を取得
```

**Git状態の確認:**
```bash
git status
git log --oneline -5
```

---

### 2. 進捗サマリー生成

```markdown
## 📋 セッション終了サマリー

### 完了したこと
- ✅ {completed_task_1}
- ✅ {completed_task_2}

### 未完了（次回継続）
- 🔄 {in_progress_task} - {進捗状況}
- ⏸️ {pending_task}

### 成果物
| 種別 | 内容 |
|------|------|
| コミット | {commit_count}件 ({commit_hashes}) |
| 新規ファイル | {new_files} |
| 変更ファイル | {modified_files} |

### 未コミットの変更
{git status の結果、あれば}
```

---

### 3. 再開用プロンプト生成

```markdown
## 🔄 次回再開用

### 再開プロンプト（コピー用）
> {task_description}
> 前回の進捗: {progress_summary}
> 残タスク: {remaining_tasks}
> 続きから再開してください。

### コンテキスト
- **ブランチ**: {current_branch}
- **最後のコミット**: {last_commit_hash} - {last_commit_message}
- **TaskList ID**: {task_list_id}（あれば）
```

---

### 4. 未コミット変更の処理提案

未コミットの変更がある場合：

```markdown
## ⚠️ 未コミットの変更あり

以下の選択肢があります:

1. **コミットする** - 変更を保存してセッション終了
2. **スタッシュする** - `git stash` で一時保存
3. **そのまま終了** - 変更は残るが、明示的な記録なし

どうしますか？
```

---

### 5. 再開用コンテキストをファイルに保存

```bash
# .claude/session-context.md に保存
cat > .claude/session-context.md << 'EOF'
# セッションコンテキスト

## 前回の作業
- **日時**: {timestamp}
- **ブランチ**: {current_branch}
- **最後のコミット**: {last_commit_hash} - {last_commit_message}

## 進捗
- 完了: {completed_tasks}
- 未完了: {remaining_tasks}

## 再開用プロンプト
{resume_prompt}

## 次にやること
{next_actions}
EOF
```

> 💡 次のセッション開始時に自動で読み込まれる

---

### 5.5 開発日誌へ追記（積み上げ）

`session-context.md` は上書きだが、`history/journal.md` は**日々積み上げる引き継ぎ日誌**。
最新の日付エントリを**先頭に追記**する（既存エントリは消さない）。

```bash
# ディレクトリの準備のみ。エントリ追記は下記の書式で行う
mkdir -p history
# ※ journal.md は gitignore 済み（クライアントに渡らない・ローカル保全）
```

追記する書式（`history/journal.md` 冒頭の運用ルールに準拠）:

```markdown
## {YYYY-MM-DD}

### やったこと
- {完了したこと}

### 翌日への引き継ぎ
- {次回継続・判断メモ・クライアントとのやり取り}
```

- **書く**: ①その日やったこと ②翌日への引き継ぎ ③その場の判断メモ
- **書かない**: 反省・振り返り・感情ログ（コストが高い）
- 同じ日に複数セッションがある場合は、その日のエントリに追記する

---

### 5.6 自律ループの中断状態を拾う（Loop Engineering 連携）

> 設計根拠: `meta/adr-lite.md` の **ADR-012**
>
> `/auto-task` `/auto-bug` 等の自律ループスキルは実行中に `history/loop-state.md` へ状態を逐次書き出している。
> セッション終了時にこのファイルを読み、**未完了ループがあれば journal に「中断・再開ポイント」を明示**して、次セッションで `session-start` が拾えるようにする。

#### 手順

1. **状態ファイルの存在確認**
   ```bash
   [ -f history/loop-state.md ] && cat history/loop-state.md
   ```

2. **最新エントリの `status` を判定**
   - `status: completed` → 正常終了。次の手順はスキップして良い。完了済みエントリはアーカイブ（ファイル末尾に "completed" セクションへ移動）または削除して構わない
   - `status: in_progress` → **中断**。下記の引き継ぎ追記を行う
   - `status: blocked_by_bug` / `blocked_by_user_confirm` → ブロック中。原因を journal へ転記

3. **journal.md の「翌日への引き継ぎ」に明示**

   今日のエントリの「翌日への引き継ぎ」セクションに、次の形で追加:

   ```markdown
   ### 翌日への引き継ぎ
   - ...（既存の引き継ぎ）
   - 🔄 **中断中の自律ループ**: `/auto-task #<issue>` （branch: `<branch>`）
     - 最終アクション: `<last_action>`
     - 完了済みステップ: `task-run`, `local-checks` まで
     - 残ステップ: `basic-review` 以降
     - **再開**: 同じ Issue 番号で `/auto-task #<issue>` を再起動するとループが続きから判定して再開
   ```

4. **状態ファイルは消さない**: 次セッションで `session-start` も拾うため、`status: completed` 以外は保持

#### 注意

- usage 切れ・API エラーで強制終了した場合、最終ステップが flush されていない可能性がある → `history/loop-state.md` の `last_action` と `git log` を突き合わせて実態を判断する
- 課金前確認プロンプトで止まった場合は `status: blocked_by_user_confirm` を期待。これも引き継ぎへ記録

---

### 6. 終了確認

```markdown
---

## ✅ セッション終了

**進捗**: {completed}/{total} タスク完了
**コンテキスト保存**: .claude/session-context.md
**次回再開**: 自動で読み込まれます

お疲れ様でした！

---
```

---

## 出力例

```markdown
## 📋 セッション終了サマリー

### 完了したこと
- ✅ PR #123 のレビューコメント対応（3件中2件）
- ✅ コミット2件作成

### 未完了（次回継続）
- 🔄 コメント#3の対応 - コード確認中
- ⏸️ git push

### 成果物
| 種別 | 内容 |
|------|------|
| コミット | 2件 (abc1234, def5678) |
| 変更ファイル | src/foo.ts, src/bar.ts |

---

## 🔄 次回再開用

### 再開プロンプト（コピー用）
> PR #123 のレビュー対応を再開
> 前回: コメント#1,#2 対応済み、#3 が残り
> `/pr-respond 123` で #3 から再開してください

### コンテキスト
- **ブランチ**: fix/review-123
- **最後のコミット**: def5678 - fix: nullチェック追加

---

## ✅ セッション終了

**進捗**: 2/3 タスク完了
**次回再開**: 上記プロンプトをコピーして使用

お疲れ様でした！
```

---

## 連携スキル

- `/session-start` - セッション開始時のゴール・完了条件明確化
- `/pr-respond` - PRレビューコメント対応
- `/task-run` - Issueベースのタスク実行

---

## 注意事項

- **未コミットの変更は必ず確認**してから終了する
- 再開プロンプトは**具体的に**（曖昧だと次回コンテキストが失われる）
- TaskListがある場合は**タスク状態も更新**してから終了

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {短く理由を記載}
