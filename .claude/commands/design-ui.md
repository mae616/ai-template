# [デザイン] 2. JSONを参照して静的UI骨格を生成

## コマンド: /design-ui [$TARGET]
設計JSON（tokens/components/design_context）を参照し、**静的UI骨格**のみ生成。
ロジック/状態/データ取得は入れない。ターゲットは **doc/rdd.md** の技術スタックを既定とし、引数で上書きする場合は **ADR-lite承認必須**。

## 共通前提（参照）
- 口調・出力規約・差分出力の方針は `CLAUDE.md` に従う。
- `doc/rdd.md` を読み、該当する `.claude/skills/*` を適用して判断軸を揃える（例: `tailwind` / `creative-coder`）。
- 詳細運用（サンプル運用/依存評価補助/ADR-lite）は `doc/ai_guidelines.md` を参照。

### 入力
- $TARGET（任意）: react | vue | svelte | swiftui | flutter | web-components | plain-html など

### 出力（差分のみ）
- スタック別の標準配置へ静的UIファイル一式
  - 例: React → `src/components/*`, `src/stories/*`, `tailwind.config.js`(tokens反映)
  - 例: Vue → `src/components/*.vue`, `src/stories/*`
  - 例: SwiftUI → `Sources/UI/*`
- Storybook/プレビュー（対応スタックのみ）

### 前提（入力ファイル）
- `doc/design/design-tokens.json`
- `doc/design/components.json`
- `doc/design/design_context.json`
（通常は `/design-ssot` の成果物）

### 参照（スキーマ）
- constraints/resizing/autoLayout の解釈とレスポンシブ対応表は `doc/design/ssot_schema.md` を参照する

### レスポンシブ適用規則（Figma→CSS/スタイル）
- Auto Layout → `flex` 等 + tokens の `gap/padding`
- constraints/resizing マッピング
  - horizontal: SCALE → `w-full` / `flex-grow` 等
  - vertical: TOP_BOTTOM → `h-full`（文脈でcol）
  - resizing: FILL → `flex-1` / `w-full`
  - resizing: HUG → `inline-size: max-content` / `inline-block`
- breakpoints → `doc/design/design-tokens.json` の `primitives.breakpoints` 準拠
- **tokens外の値禁止 / magic number禁止**

### 禁止
- 状態/ロジック/フェッチの追加
- RDD逸脱スタックの導入（$TARGET指定時はADR-lite要）

### ゲート
- 見た目一致（主要variantsのプレビュー/Story）
- tokens外の値0件 / Lint/Type green
- ここで停止
