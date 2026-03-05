---
user-invocable: true
description: セッション開始時にプロジェクトの前提（CLAUDE.md / rdd.md / スキル一覧）を読み込む。最初に実行することを推奨。
---

# セットアップ: 前提の読み込み

`doc/input/rdd.md`（先頭のAI用事実ブロック）を読み、技術スタックや制約に応じて `.claude/skills/*` を選択・併用してください。

## デザイン作業（Figma）をする場合の追加前提
- `/design-ssot` を使う場合、Figma MCP（Dev Mode）が利用可能である必要がある。
- 迷ったら `claude mcp list` を確認し、`figma` が登録されていることを確かめる（未登録/未起動なら `/design-ssot` の事前チェック手順に従う）。
