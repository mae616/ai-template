# [デザイン] 1. SSOT（tokens/components/context）を生成（Figmaルート）

## コマンド: /design-ssot $FIGMA_REF
Figma MCPから設計情報を抽出し、AI/人間が参照するSSOTを作る。**実装はしない**。

## 共通前提（参照）
- 口調・出力規約・差分出力の方針は `CLAUDE.md` に従う。
- `/doc/rdd.md` を読み、該当する `.claude/skills/*` を適用して判断軸を揃える（例: `ui-designer` / `usability-psychologist`）。
- 詳細運用（サンプル運用/依存評価補助/ADR-lite）は `doc/ai_guidelines.md` を参照。

### 入力
- $FIGMA_REF: Figmaファイル/ページ識別子（MCPが認識できる指定）

### 出力（差分のみ）
- doc/design/design_context.json   # 画面/レイアウト/constraints/resizing
- doc/design/design-tokens.json    # 色/タイポ/spacing/半径/影/breakpoints（単位明記）
- doc/design/components.json       # 主要コンポーネント + variants（例: size/tone/state）

### ルール
- JSONは**単位明記**（px/%/unitless）
- tokens は「物理値」と「semantic（意味）」を混ぜない（例: `color.gray.900` と `color.text.primary` を分け、semanticは物理へ参照する）
- variants は **props/属性に落とせる粒度**（例: { size:["sm","md","lg"] }）
- **RDD遵守**（doc/rdd.md のスタック/制約に反しない）
- 技術スタックの既定は `doc/rdd.md`。このコマンドの出力（SSOT JSON）は可能な限りスタック非依存に保ち、後続（`/design-ui` / `/design-assemble`）が `doc/rdd.md` を参照して生成する。
- SSOTの最低限スキーマは `doc/design/ssot_schema.md` を参照。
- `doc/design/components.json` の variants 命名規約は `doc/design/ssot_schema.md` に従い、プロジェクト横断で揃える。
- ここで停止

### ゲート
- tokens/variantsに未定義値なし
- design_context.json に constraints/resizing が含まれる
- components.json のvariantsが「実装の分岐」に落とせる粒度になっている
