# Claude Code スキル（手順系）カタログ（索引）

このページは `.claude/skills/*/SKILL.md`（手順系 = `user-invocable: true`）の一覧と、命名ルール・推奨フローをまとめます。

> **Note**: v1.0 より `.claude/commands/*.md` は `.claude/skills/*/SKILL.md` に移行しました。
> スラッシュコマンド（`/setup` など）は引き続き同じ名前で呼び出せます。

## 命名ルール（重要）
- **カテゴリ接頭辞 + 動詞** に統一する（例: `task-list`, `bug-new`）。
- 手順系スキルは **`user-invocable: true`** を設定し、スラッシュコマンドとして呼び出し可能にする。
- 判断軸は `CLAUDE.md` / `doc/rdd.md` / `.claude/skills/*`（判断軸系） / `doc/ai_guidelines.md` を参照する。

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
- デザイン（会話起点）: `/design-mock` → `/design-ui` → `/design-components` → `/design-assemble`
  - 補足: `/design-mock` が `mock.html`（1枚ペラ）を出した場合のみ、必要に応じて `/design-split` を使う
- デザイン（Figma起点）: `/design-ssot` → `/design-ui` → `/design-components` → `/design-assemble`
  - 補足: 静的HTMLが欲しい場合のみ `/design-html`（任意）
  - 補足: 1枚ペラHTMLをページ分割したい場合のみ `/design-split`（任意）
- 壁打ち: `/pair plan|design|arch|dev`
- 初見: `/repo-tour`

## コマンド一覧

### setup
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/setup` | 前提読み込み（`CLAUDE.md` → `doc/rdd.md` → skills → `doc/ai_guidelines.md`） | - |

### commit
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/commit-msg` | ステージ差分から日本語コミットメッセージ生成 | `developer-specialist` |

### task
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/task-list` | タスクリスト生成 | `developer-specialist` |
| `/task-gen` | スプリントTASK生成 | `developer-specialist`, `architecture-expert` |
| `/task-run` | TASK実行 | `developer-specialist` + 技術スタック系 |

### bug
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/bug-new` | トラブルシュートログ生成 | `developer-specialist` |
| `/bug-investigate` | 調査と仮説の絞り込み | `developer-specialist`, `security-expert`（必要時） |
| `/bug-propose` | 修正案の根拠付き列挙 | `developer-specialist`, `architecture-expert` |
| `/bug-fix` | 修正実行（恒久対応・段階実施＋無効時ロールバック） | `developer-specialist` + 技術スタック系 |

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

### pair
| コマンド | 説明 | 推奨スキル |
|----------|------|-----------|
| `/pair` | 壁打ち（`plan`/`design`/`arch`/`dev`） | モードに応じて選択 |
| `/repo-tour` | リポジトリ内容の説明（初見向け） | `architecture-expert` |

### 技術スタック系スキルの適用条件
`doc/rdd.md` の技術スタックに応じて以下を自動適用する：
- React / Next.js → `react`
- Svelte / SvelteKit → `svelte`
- Astro → `astro`
- Tailwind CSS → `tailwind`

## 旧コマンド（deprecated）
旧名は削除済み。今後はこのページを「現行コマンドのみ」の索引として運用する。

