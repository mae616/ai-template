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

### 新規プロジェクト作成

```
/project-init
```

壁打ち（要件定義）→ rdd.md → ボイラーテンプレート → AIテンプレート適用を対話形式で実行。

### タスク実行（スクラムサイクル）

GitHub Issue/Milestone + Claude Code組み込みTaskを連携して管理します。

```
/task-list doc/input/rdd.md   # 1. Sprint計画 → GitHub Milestone + Issue生成
/task-detail sprint-1          # 2. Issue詳細化 + 依存関係設定
/task-run #123                 # 3. 依存解決済みIssueを実装 → 完了時にIssue close
```

### バグ対応（Issue → PR）

```
/bug-new podmanが起動しない    # 1. GitHub Issue起票（再現手順・仮説を記録）
/bug-investigate #123          # 2. 調査 → Issueコメントに追記
/bug-propose #123              # 3. 修正案をIssueコメントに追記（任意）
/bug-fix #123                  # 4. ブランチ作成 → 実装 → PR（Fixes #123）
```

### デザイン連携（SSOT → 実装）

技術スタックは [doc/input/rdd.md](doc/input/rdd.md)、SSOTスキーマは [doc/input/design/ssot_schema.md](doc/input/design/ssot_schema.md) がSSOT。

**会話起点（叩き台から）:**
```
/design-mock                   # 1. 会話からSSOT JSON + HTML叩き台を生成
/design-ui                     # 2. SSOT → 技術スタック準拠の静的UI骨格
/design-components src         # 3. UI骨格 → コンポーネント/レイアウト分割
/design-assemble vue           # 4. variants → 型付きPropsへマッピング・結合
```

**Figma起点（Dev Mode → SSOT）:**
```
/design-ssot HomePage=https://...   # 1. Figma MCPからSSOT JSON確立
/design-ui                          # 2〜4は同じ
/design-components src
/design-assemble vue
```

- `/design-html`: SSOT → ドキュメント/共有用の静的HTML生成（任意）
- `/design-mock` の反復: HTML調整後、差分を会話で共有 → 再実行でHTML+SSOTを同時更新

### レビュー・PR対応

```
/basic-review                  # typo/命名/フォーマットの表面チェック
/deep-review                   # 設計/セキュリティ/RDD整合の深掘り
/pr-respond #45                # PRレビューコメントに1件ずつ対応 → コミット → push
```

### セッション管理

```
/session-start                 # ゴール・完了条件・タイムボックスを設定
# ... 作業 ...
/session-end                   # 進捗サマリー・再開用プロンプトを生成
```

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
│   ├── skills/           # スキル（手順系25 + 判断軸16）
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
