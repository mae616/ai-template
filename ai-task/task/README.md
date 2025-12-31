# ai-task/task（開発タスク）

このフォルダは、`/task-list` / `/task-gen` / `/task-run` が扱う **開発タスクの置き場**です。

## 推奨構成
- `ai-task/task/{feature}/`
  - `TASK-LIST-{feature}.md`（スプリント計画つきのタスクリスト）
  - `TASK_{sprint}_{feature}_{short}.md`（実行単位のTASK）

## 基本方針
- **1 feature = 1ディレクトリ**（タスクの散逸を防ぐ）
- `/task-gen` と `/task-run` は **同じTASKファイルを追記更新**して進捗と完了報告を残す

## 使い方（例）
```bash
/task-list doc/rdd.md
/task-gen ai-task/task/auth/TASK-LIST-auth.md sprint1
/task-run ai-task/task/auth/TASK_sprint1_auth_login.md
```

