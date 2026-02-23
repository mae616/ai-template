# Claude Code skills カタログ（判断軸系）

このページは `.claude/skills/*/SKILL.md`（判断軸系 = AIが状況に応じて自動適用）の一覧です。
プロジェクトの事実は `doc/input/rdd.md`（先頭のAI用事実ブロック）に書き、適用すべきskillを選びます。

> **手順系スキル**（`/setup`, `/commit-msg` など）は `doc/guide/commands_catalog.md` を参照してください。

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
- `sensory-design`: 感覚デザイン（サウンド/ハプティクス/空間知覚）をa11yを損なわず設計する判断軸

## 開発
- `architecture-expert`: 境界/依存/非機能/運用をトレードオフで設計（ADR-lite）
- `developer-specialist`: 設計&実装をTDD/差分最小で進める
- `testing`: t_wada流TDD（RED→GREEN→REFACTOR）を軸にテストピラミッド・テスト設計・品質戦略を整理
- `security-expert`: OWASP基本を前提にデフォルト安全で設計・実装・レビュー
- `frontend-implementation`: Figma/UI要件を「比率・構造・制約・状態」で実装へ翻訳（px写経を避ける）
- `accessibility-engineer`: セマンティックHTML/JSXとWAI-ARIAを最小で正しく適用し、キーボード/スクリーンリーダを満たす実装規約
## フレームワーク
- `astro`
- `react`
- `svelte`
- `tailwind`
- `playwright`: Playwright E2Eテストのロケーター選択・自動待機・テスト分離・CI最適化

## クリエイティブ・アニメーション
- `animation-principles`: ディズニー12原則+ジブリ的自然運動をUIモーション設計に適用（ツール非依存）
- `creative-coder`: 体験品質（動き/触感）をa11y/性能を守って実装
- `gsap`: GSAP（GreenSock）のTween/Timeline/ScrollTrigger/Easingでウェブアニメーション最適化
- `p5js`: P5.js（Processing由来）のsetup/drawループでクリエイティブコーディング
- `threejs`: Three.js（WebGL）のScene-Camera-Renderer三位一体と手動メモリ管理
- `blender`: Blender MCP（JSON-RPC over TCP）でプリミティブ→スカルプティング段階的3Dモデリング

## ツール・UI検証
- `agent-browser`: Agent Browser（Headlessブラウザ自動化CLI）によるUI検証・E2Eテスト・スクリーンショット取得

