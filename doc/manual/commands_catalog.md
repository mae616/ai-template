# Claude Code カスタムコマンド カタログ（索引）

このページは `.claude/commands/*.md` の一覧と、命名ルール・推奨フローをまとめます。

## 命名ルール（重要）
- **カテゴリ接頭辞 + 動詞** に統一する（例: `task-list`, `bug-new`）。
- コマンドは **手順（I/O）** だけを持ち、判断軸は `CLAUDE.md` / `doc/rdd.md` / `.claude/skills/*` / `doc/ai_guidelines.md` を参照する。

## 参照の優先順位（SSOT）
1. `CLAUDE.md`（憲法）
2. `doc/rdd.md`（プロジェクト固有の事実）
3. `.claude/skills/*/SKILL.md`（判断軸）
4. `doc/ai_guidelines.md`（詳細運用）

## 推奨フロー（よく使う順）
- セットアップ: `/setup`
- コミット文: `/commit-msg`（ステージ差分から日本語コミットメッセージ生成）
- タスク: `/task-list` → `/task-gen` → `/task-run`
- バグ: `/bug-new` → `/bug-investigate` → `/bug-propose` → `/bug-fix`
- デザイン（会話起点）: `/design-mock` → `/design-split` → `/design-ui` → `/design-components` → `/design-assemble`
- デザイン（Figma起点）: `/design-ssot` → `/design-html` → `/design-split` → `/design-ui` → `/design-components` → `/design-assemble`
- 壁打ち: `/pair plan|design|arch|dev`
- 初見: `/repo-tour`

## コマンド一覧
### setup
- `/setup`: 前提読み込み（`CLAUDE.md` → `doc/rdd.md` → skills → `doc/ai_guidelines.md`）

### commit
- `/commit-msg`: ステージ差分から日本語コミットメッセージ生成

### task
- `/task-list`: タスクリスト生成
- `/task-gen`: スプリントTASK生成
- `/task-run`: TASK実行

### bug
- `/bug-new`: トラブルシュートログ生成
- `/bug-investigate`: 調査と仮説の絞り込み
- `/bug-propose`: 修正案の根拠付き列挙
- `/bug-fix`: 修正実行（恒久対応・段階実施＋無効時ロールバック）

### design
- `/design-ssot`: SSOT（tokens/components/context）を生成（Figmaルート）
- `/design-html`: SSOT JSONから静的HTML生成
- `/design-mock`: 会話から1枚ペラの静的HTML生成（SSOT JSONも同時に用意）
- `/design-split`: 1枚ペラHTMLをページ単位に分割
- `/design-ui`: JSONから静的UI骨格生成
- `/design-components`: 静的UI骨格をコンポーネント化して分離
- `/design-assemble`: variantsを型付きPropsへマッピングして結合

### manual
- `/manual-gen`: 手順書生成
- `/manual-guide`: 手順書をステップ実行支援でガイド

### docs
- `/docs-reverse`: 逆生成ドキュメント作成

### pair
- `/pair`: 壁打ち（`plan`/`design`/`arch`/`dev`）
- `/repo-tour`: リポジトリ内容の説明（初見向け）

## 旧コマンド（deprecated）
旧名は削除済み。今後はこのページを「現行コマンドのみ」の索引として運用する。

