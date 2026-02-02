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
4. `doc/guide/ai_guidelines.md`（詳細運用）

## 推奨フロー（よく使う順）
- セットアップ: `/setup`
- タスク（GitHub + 組み込みTask連携）: `/task-list` → `/task-detail` → `/task-run`
  - Sprint = Milestone、タスク = Issue + 組み込みTask（並行・依存管理）
  - 進捗は組み込みTaskとIssueの両方に同期
- バグ（GitHub連携）: `/bug-new` → `/bug-investigate` → `/bug-propose` → `/bug-fix`
  - bug-new〜bug-propose は Issue で管理（調査・議論）
  - bug-fix は PR を作成し、`Fixes #...` で Issue に紐づけ
- デザイン（会話起点）: `/design-mock` → `/design-ui` → `/design-components` → `/design-assemble`
- デザイン（Figma起点）: `/design-ssot` → `/design-ui` → `/design-components` → `/design-assemble`
- 壁打ち: `/pair plan|design|arch|dev`
- 初見: `/repo-tour`

### デザインフロー詳細（design-html / design-split の使い分け）

```
【会話起点】                              【Figma起点】
    │                                        │
    ▼                                        ▼
/design-mock ──→ mock.html（1枚ペラ）   /design-ssot ──→ JSON（SSOT）
    │               │                        │              │
    │               ▼                        │              ▼
    │         /design-split（任意）          │        /design-html（任意）
    │               │                        │              │
    │               ▼                        │              ▼
    │         {page}.html 複数               │        {page}.html 複数
    │                                        │
    └──────→ JSON（SSOT）も同時生成 ─────────┘
                        │
                        ▼
              /design-ui → /design-components → /design-assemble
```

| コマンド | 入力 | 出力 | いつ使う |
|----------|------|------|----------|
| `/design-html` | JSON（SSOT） | `{page}.html` | SSOT JSONから静的HTMLを生成したいとき（レビュー/共有用） |
| `/design-split` | 1枚ペラHTML | `{page}.html` | `/design-mock` の1枚ペラをページ単位に分割したいとき |

> **ポイント**: どちらも最終出力は `doc/input/design/html/{page}.html` だが、**入力が違う**。
> - `/design-html` は JSON → HTML（Figma起点で静的確認が欲しいとき）
> - `/design-split` は HTML → HTML（会話起点で1枚ペラを分割したいとき）

## コマンド一覧

### setup
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/setup` | 前提読み込み（`CLAUDE.md` → `doc/input/rdd.md` → skills → `doc/guide/ai_guidelines.md`） | - |

### task（GitHub Issue/Milestone + 組み込みTask連携）
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/task-list` | Sprint計画（Milestone + Issue一括作成 + 組み込みTask登録） | `developer-specialist` |
| `/task-detail` | Issue詳細化 + 依存関係設定（blocks/blockedBy） | `developer-specialist`, `architecture-expert` |
| `/task-run` | Issue実行 + 進捗同期（組み込みTask ↔ GitHub Issue） | `developer-specialist` + 技術スタック系 |

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
| `/design-split` | 1枚ペラHTMLをページ単位に分割 | `ui-designer` |
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
| `/skill-create` | 新しいスキルを壁打ち→テンプレ生成→登録確認まで | - |

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

## 旧コマンド（deprecated）
旧名は削除済み。今後はこのページを「現行コマンドのみ」の索引として運用する。

