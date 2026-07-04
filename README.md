# ai-template

Claude Code 向けの開発プロンプトテンプレート。スキル（`/command`）と判断軸で、人間とAIの協調開発を構造化します。

参考: [Cole Medin氏 context-engineering-intro](https://github.com/coleam00/context-engineering-intro)

## 前提条件

| 必須/任意 | ツール | 用途 | 公式 |
|-----------|--------|------|------|
| **必須** | Claude Code | コア | [公式](https://www.anthropic.com/claude-code) |
| **必須** | GitHub CLI | task/bug管理 | [公式](https://cli.github.com/) |
| 任意 | Figma MCP | デザインSSOT取得 | [公式ガイド](https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server) |
| 任意 | mise | ツール管理 | [公式](https://mise.jdx.dev/) |

## セットアップ

### プロジェクトへの適用

```bash
# dry-run で確認後、実行
scripts/apply_template.sh --target /abs/path/to/your-project --safe --dry-run
scripts/apply_template.sh --target /abs/path/to/your-project --safe
```

- `--safe`（デフォルト）: 既存ファイルを上書きしない。`--force` で上書き、`--sync` で同期+削除
- `--no-skills`: `.claude/` のコピーをスキップ（グローバル適用済みの場合）
- `doc/input/rdd.md` は原則プロジェクト固有。上書きは `--overwrite-rdd` で明示

### グローバル適用（~/.claude）

```bash
scripts/apply_global.sh --dry-run      # 確認
scripts/apply_global.sh                # 判断軸スキルのみ
scripts/apply_global.sh --all-skills   # 手順系スキルも含む
```

適用対象: skills / hooks / rules / settings.json / CLAUDE.md

### 言語・フレームワーク固有のスキル

React / Svelte / Tailwind / GSAP / Three.js / Blender 等の技術スタック固有スキルは **[ai-tech-knowledge](https://github.com/mae616/ai-tech-knowledge)** で管理しています。必要な技術のスキルをそちらから追加してください。

## コマンドフロー

すべてのセッションは `/setup` で開始します（`/clear` → `/setup` が前提）。

### 自律ループ（Loop Engineering）

1コマンドでゴールまで自律実行する親スキル群。既存スキルを連鎖呼び出しし、人間の関所を最小限に絞って設計しています（設計根拠: `meta/adr-lite.md` ADR-008/014/015）。

| コマンド | 入力 → ゴール | 人間の関所 |
|---------|--------------|-----------|
| `/auto-build "プロンプト文"` or `成果物パス` | 要件定義 → Sprint計画 → 全タスク自律実装 → エビデンスHTML提示 | rdd.md確認（プロンプト起点時）/ sprint→main マージ |
| `/auto-task #123` | 1タスクの実装 → テスト → レビュー収束 → task→sprint 自律マージ | 危険変更該当時のマージ判断 |
| `/auto-design <Figma URL/会話/SSOT>` | デザインSSOT → UI骨格 → 型付きコンポーネント → マージ | Vibe Coding（触って確認） |
| `/auto-bug #123` | bug調査 → 修正案の試行・効果検証 → マージ | 危険変更該当時のマージ判断 |

**共通の停止条件**: レビュー反復の上限超過 / bug連鎖3周で未解決 / 危険変更チェックリスト該当（`.claude/rules/code-quality.md`）/ 課金発生前。中断時は `history/loop-state.md` から再開できます。

### 手動フロー（1ステップずつ進めたい場合）

各コマンドの詳細な流れは `.claude/skills/*/SKILL.md` に記載しています。

| 領域 | コマンド連鎖 |
|------|------------|
| プロジェクト開始 | `/project-init`（壁打ち → rdd.md → テンプレート適用） |
| タスク | `/task-list` → `/task-detail` → `/task-run` |
| バグ | `/bug-new` → `/bug-investigate` → `/bug-propose` → `/bug-fix` |
| デザイン | `/design-mock`（会話起点）or `/design-ssot`（Figma起点）→ `/design-ui` → `/design-components` → `/design-assemble`（任意: `/design-html`） |
| レビュー・PR | `/basic-review` → `/deep-review` / `/pr-respond` |
| セッション | `/session-start` → 作業 → `/session-end` |

### 補助コマンド

| コマンド | 用途 |
|---------|------|
| `/repo-tour` | リポジトリ構造の案内（初見向け） |
| `/pair plan\|design\|arch\|dev` | 壁打ち（短い反復で方針を固める） |
| `/manual-gen` | 手順書を `doc/generated/manual/` に生成 |
| `/manual-guide` | 生成済み手順書をステップごとに案内 |
| `/docs-reverse` | コードベースから俯瞰ドキュメントを `doc/generated/reverse/` に生成 |

## Gitブランチ運用

```
main
├── sprint/*          ← スプリント単位（CI通過後にmainへマージ）
│   ├── task/*        ← タスク単位（AI実装）
│   └── feature_fix/* ← スプリント統合後のバグ修正
└── hotfix/*          ← 本番緊急修正
```

詳細は [.claude/rules/git.md](.claude/rules/git.md) を参照（Claude Codeが自動読み込み）。

## プロジェクト構成

```
ai-template/
├── .claude/
│   ├── skills/           # スキル（自律ループ / 手順系 / 判断軸）
│   ├── hooks/            # フック（Mermaid構文検証等）
│   ├── rules/            # 運用ルール（自動適用）
│   └── settings.json     # 権限・hooks設定
├── doc/
│   ├── input/            # 【人間が書く】SSOT（rdd.md / architecture.md / design/）
│   └── generated/        # 【AI生成】上書きOK（manual/ / reverse/）
├── scripts/
│   ├── apply_template.sh # プロジェクトへの適用
│   └── apply_global.sh   # ~/.claude への適用
├── CLAUDE.md             # AI判断基準（普遍ルール）
└── README.md
```

### 判断軸スキル（AIが状況に応じて自動適用）

| カテゴリ | スキル |
|---------|--------|
| 事業 | `biz-researcher` / `persona-designer` / `proposition-reviewer` |
| デザイン | `ui-designer` / `usability-psychologist` / `sensory-design` |
| 開発 | `architecture-expert` / `developer-specialist` / `testing` / `security-expert` / `frontend-implementation` / `accessibility-engineer` / `keyboard-shortcuts` |
| クリエイティブ | `creative-coder` / `animation-principles` |
| ツール | `agent-browser` |

> 各スキルの詳細は `.claude/skills/*/SKILL.md` を参照

## ライセンス

[MIT License](LICENSE)

## コントリビューション

Feedback only OSS。[CONTRIBUTING.md](CONTRIBUTING.md) を参照。

## 参考

- [MCP Protocol](https://modelcontextprotocol.io/) / [Figma MCPカタログ](https://www.figma.com/ja-jp/mcp-catalog/)
- [Claude Code](https://www.anthropic.com/claude-code) / [mise](https://mise.jdx.dev/)
