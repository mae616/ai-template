# Claude Code スキル（手順系）カタログ（索引）

このページは `.claude/skills/*/SKILL.md`（手順系 = `user-invocable: true`）の一覧と、命名ルール・推奨フローをまとめます。

> **Note**: v1.0 より `.claude/commands/*.md` は `.claude/skills/*/SKILL.md` に移行しました。
> スラッシュコマンド（`/setup` など）は引き続き同じ名前で呼び出せます。

## 命名ルール（重要）
- **カテゴリ接頭辞 + 動詞** に統一する（例: `task-list`, `bug-new`）。
- 手順系スキルは **`user-invocable: true`** を設定し、スラッシュコマンドとして呼び出し可能にする。
- 判断軸は `CLAUDE.md` / `doc/input/rdd.md` / `.claude/skills/*`（判断軸系） / `doc/guide/ai_guidelines.md` を参照する。

## 参照の優先順位（SSOT）
1. `CLAUDE.md`（憲法）
2. `doc/input/rdd.md`（プロジェクト固有の事実）
3. `.claude/skills/*/SKILL.md`（判断軸）
4. `doc/guide/*.md`（運用ガイド：ai_guidelines / git_workflow / team_protocol / design_workflow 等）

## 推奨フロー（よく使う順）
- **新規プロジェクト**: `/project-init`（壁打ち → 要件定義 → ボイラーテンプレート → AIテンプレート適用）
- セットアップ: `/setup`
- タスク（GitHub + 組み込みTask連携）: `/task-list` → `/task-detail` → `/task-run`
  - Sprint = Milestone、タスク = Issue + 組み込みTask（並行・依存管理）
  - 進捗は組み込みTaskとIssueの両方に同期
- バグ（GitHub連携）: `/bug-new` → `/bug-investigate` → `/bug-propose` → `/bug-fix`
  - bug-new〜bug-propose は Issue で管理（調査・議論）
  - bug-fix は PR を作成し、`Fixes #...` で Issue に紐づけ
- デザイン（会話起点）: `/design-mock` → (`/design-html`) → `/design-ui` → `/design-components` → `/design-assemble`
- デザイン（Figma起点）: `/design-ssot` → (`/design-html`) → `/design-ui` → `/design-components` → `/design-assemble`
- 壁打ち: `/pair plan|design|arch|dev`
- 初見: `/repo-tour`

### デザインフロー詳細

```
【会話起点】                              【Figma起点】
    │                                        │
    ▼                                        ▼
/design-mock ──→ SSOT JSON + HTML叩き台  /design-ssot ──→ JSON（SSOT）
    │                                        │
    └──────────────┬─────────────────────────┘
                   │
                   ▼
         /design-html（任意: ページ単位HTML生成）
                   │
                   ▼
         /design-ui → /design-components → /design-assemble
```

| コマンド | 入力 | 出力 | いつ使う |
|----------|------|------|----------|
| `/design-html` | JSON（SSOT） | `{page}.html` | SSOT JSONからページ単位の静的HTMLを生成したいとき（レビュー/共有用） |

> **Note**: 旧 `/design-split`（1枚ペラHTML → ページ分割）の役割は `/design-html` に統合済み。

## コマンド一覧

### project（プロジェクト初期化）
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/project-init` | 壁打ち→要件定義→ボイラーテンプレート作成→AIテンプレート適用を一気通貫 | `architecture-expert`, `developer-specialist` |

### setup
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/setup` | 前提読み込み（`CLAUDE.md` → `doc/input/rdd.md` → skills → `doc/guide/ai_guidelines.md`） | - |

### task（GitHub Issue/Milestone + 組み込みTask連携）
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/task-list` | Sprint計画（Milestone + Issue一括作成 + 組み込みTask登録） | `developer-specialist` |
| `/task-detail` | Issue詳細化 + 依存関係設定（blocks/blockedBy） | `developer-specialist`, `architecture-expert` |
| `/task-run` | Issue実行 + 進捗同期（組み込みTask ↔ GitHub Issue） | `developer-specialist`, `testing` + 技術スタック系 |

### bug（GitHub Issue → PR連携）
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/bug-new` | GitHub Issue でトラブルシュートログ生成 | `developer-specialist` |
| `/bug-investigate` | Issue コメントで調査と仮説の絞り込み | `developer-specialist`, `security-expert`（必要時） |
| `/bug-propose` | Issue コメントで修正案の根拠付き列挙 | `developer-specialist`, `architecture-expert` |
| `/bug-fix` | PR 作成、`Fixes #...` で Issue 紐づけ | `developer-specialist` + 技術スタック系 |

### design
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/design-ssot` | SSOT（tokens/components/context）を生成（Figmaルート） | `ui-designer`, `frontend-implementation` |
| `/design-html` | SSOT JSONから静的HTML生成 | `ui-designer`, `tailwind`（使用時） |
| `/design-mock` | 会話から1枚ペラの静的HTML生成（SSOT JSONも同時に用意） | `ui-designer`, `usability-psychologist`, `tailwind`（使用時） |
| `/design-ui` | JSONから静的UI骨格生成 | `ui-designer`, `frontend-implementation`, `accessibility-engineer` |
| `/design-components` | 静的UI骨格をコンポーネント化して分離 | `frontend-implementation`, `accessibility-engineer`, 技術スタック系 |
| `/design-assemble` | variantsを型付きPropsへマッピングして結合 | `frontend-implementation`, `developer-specialist`, 技術スタック系 |

### manual
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/manual-gen` | 手順書生成 | - |
| `/manual-guide` | 手順書をステップ実行支援でガイド | - |

### docs
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/docs-reverse` | 逆生成ドキュメント作成（実装から俯瞰/引き継ぎ用ドキュメント） | `architecture-expert` |

### git
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/commit-msg` | ステージ差分から日本語コミットメッセージを生成 | - |

### skill
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/skill-audit` | スキル一覧の分析・重複検出・改善提案 | - |

### review
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/basic-review` | typo/命名/フォーマットの表面チェック | `developer-specialist` |
| `/deep-review` | 設計/セキュリティ/RDD整合の深掘りチェック | `architecture-expert`, `security-expert` |

### pr
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/pr-respond` | PRレビューコメントに順次対応（fetch→リスト→対応→コミット） | `developer-specialist` |

### session
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/session-start` | 開始時のゴール・完了条件・タイムボックス明確化 | - |
| `/session-end` | 終了時の進捗サマリー・再開用プロンプト生成 | - |

### team
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/team-start` | エージェントチーム起動（tmux分割で並列開発） | `architecture-expert` |

### business
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/biz-researcher` | 市場/競合/仮説検証の調査整理 | - |
| `/persona-designer` | ペルソナ/想定ユーザー像の設計 | - |
| `/proposition-reviewer` | 価値提案レビューとMVP焦点化 | - |

> **Note**: ビジネス系3スキルは判断軸としてもAIが自動参照する（`doc/guide/skills_catalog.md` にも記載）。

### pair
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/pair` | 壁打ち（`plan`/`design`/`arch`/`dev`） | モードに応じて選択 |
| `/repo-tour` | リポジトリ内容の説明（初見向け） | `architecture-expert` |

### 技術スタック系スキルの適用条件
`doc/input/rdd.md` の技術スタックに応じて以下を自動適用する：
- React / Next.js → `react`
- Svelte / SvelteKit → `svelte`
- Astro → `astro`
- Tailwind CSS → `tailwind`
- Playwright / E2Eテスト → `playwright`

### ツール・UI検証スキルの適用条件
`doc/input/rdd.md` に以下が記載されている場合、またはブラウザ自動化/UI検証/E2Eテストの文脈で自動適用する：
- Agent Browser / E2Eテスト / UI検証 → `agent-browser`

## 旧コマンド（deprecated）
旧名は削除済み。今後はこのページを「現行コマンドのみ」の索引として運用する。

