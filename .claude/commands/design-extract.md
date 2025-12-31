# [デザイン] 1. Design Tokens / Components / Constraints をJSON化 (引数: FigmaのページのフレームのURL)  

## コマンド: /design-extract $FIGMA_REF
Figma MCPから設計情報を抽出し、AI/人間が参照するSSOTを作る。**実装はしない**。

## 共通前提（参照）
- 口調・出力規約・差分出力の方針は `CLAUDE.md` に従う。
- `/doc/rdd.md` を読み、該当する `.claude/skills/*` を適用して判断軸を揃える（例: `ui-designer` / `usability-psychologist`）。
- 詳細運用（サンプル運用/依存評価補助/ADR-lite）は `doc/ai_guidelines.md` を参照。

### 入力
- $FIGMA_REF: Figmaファイル/ページ識別子（MCPが認識できる指定）

### 出力（差分のみ）
- doc/design/design_context.json   # 画面/レイアウト/constraints/resizing
- design/design-tokens.json        # 色/タイポ/spacing/半径/影/breakpoints（単位明記）
- design/components.json           # 主要コンポーネント + variants（例: size/tone/state）

### ルール
- JSONは**単位明記**（px/%/unitless）
- variants は **props/属性に落とせる粒度**（例: { size:["sm","md","lg"] }）
- **RDD遵守**（doc/rdd.md のスタック/制約に反しない）
- ここで停止

### ゲート
- tokens/variantsに未定義値なし
- design_context.json に constraints/resizing が含まれる
