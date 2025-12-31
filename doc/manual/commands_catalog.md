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
- タスク: `/task-list` → `/task-gen` → `/task-run`
- バグ: `/bug-new` → `/bug-investigate` → `/bug-propose` → `/bug-fix`

## コマンド一覧
### setup
- `/setup`: 前提読み込み（`CLAUDE.md` → `doc/rdd.md` → skills → `doc/ai_guidelines.md`）

### task
- `/task-list`: タスクリスト生成（旧: `/generate-task-list`）
- `/task-gen`: スプリントTASK生成（旧: `/generate-task`）
- `/task-run`: TASK実行（旧: `/execute-task`）

### bug
- `/bug-new`: トラブルシュートログ生成（旧: `/generate-trouble-shooting`）
- `/bug-investigate`: 調査と仮説の絞り込み（旧: `/investigate-trouble-shooting`）
- `/bug-propose`: 修正案の根拠付き列挙（旧: `/propose-trouble-shooting`）
- `/bug-fix`: 修正実行（恒久対応・段階実施＋無効時ロールバック）（旧: `/execute-fix-trouble-shooting`）

### design
- `/design-extract`: Figma MCPからJSON化（tokens/components/constraints）
- `/design-export`: JSONから静的HTML生成（旧: `/design-export-html`）
- `/design-skeleton`: JSONから静的UI骨格生成
- `/design-bind`: variantsを型付きPropsへマッピングして結合

### manual
- `/manual-gen`: 手順書生成（旧: `/generate-manual`）
- `/manual-guide`: 手順書をステップ実行支援でガイド（旧: `/guide-manual`）

### docs
- `/docs-reverse`: 逆生成ドキュメント作成（旧: `/reverse-docs`）

## 旧コマンド（deprecated）
旧名は削除した（参照切れ防止のためドキュメント上にマッピングだけ残す）。

