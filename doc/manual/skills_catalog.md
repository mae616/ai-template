# Claude Code skills カタログ（索引）

このページは `.claude/skills/*/SKILL.md` の一覧です。  
プロジェクトの事実は `doc/rdd.md`（先頭のAI用事実ブロック）に書き、適用すべきskillを選びます。

## 命名と分類（重要）
このリポジトリのskillは、**ディレクトリ名（slug）**で識別する。  
「ロール（観点）」なのか「技術（スタック）」なのかは、各 `SKILL.md` のYAMLにある `category` で区別する。

- `category: role` … 役職/専門ロール（観点）を表すskill
- `category: tech` … 技術スタック（React/Astroなど）に紐づくskill

## 事業
- `persona-designer`: ペルソナ/想定ユーザー像の設計（※会話口調のペルソナとは別）
- `biz-researcher`: 市場/競合/仮説検証のための調査整理
- `proposition-reviewer`: 価値提案（誰に/何を/なぜ）レビューとMVP焦点化

## デザイン
- `ui-designer`: 画面目的→情報設計→コンポーネント/トークンへ落とす
- `usability-psychologist`: 認知負荷/ユーザビリティ/アクセシビリティの統合レビュー

## 開発
- `architecture-expert`: 境界/依存/非機能/運用をトレードオフで設計（ADR-lite）
- `developer-specialist`: 設計&実装をTDD/差分最小で進める
- `security-expert`: OWASP基本を前提にデフォルト安全で設計・実装・レビュー
- `creative-coder`: 体験品質（動き/触感）をa11y/性能を守って実装

## フレームワーク（既存）
- `astro`
- `react`
- `svelte`
- `tailwind`

