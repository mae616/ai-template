# [デザイン] 2. SSOT → 静的UI骨格（見た目のみ）を生成

## コマンド: /design-ui [$TARGET]
設計JSON（tokens/components/design_context）を参照し、**静的UI骨格**のみ生成。
ロジック/状態/データ取得は入れない。ターゲットは **doc/rdd.md** の技術スタックを既定とし、引数で上書きする場合は **ADR-lite承認必須**。

## いつ使う？（位置づけ）
- `/design-ssot` または `/design-mock` で **SSOT（tokens/components/context）** が揃ったあと
- 「実装スタック準拠のファイル配置」で **見た目だけの骨格**を先に作りたいとき（後で分割・結合する前提）

## 次に何をする？
- 重複UIを減らして保守しやすくする → `/design-components`
- variantsを型付きprops/属性に落として再利用UIにする → `/design-assemble`

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
 - `doc/design/assets/assets.json`（任意。存在する場合は必ず参照して画像を配置する）
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

### 画像アセット（assets.json）の適用ルール
- `doc/design/assets/assets.json` が存在する場合は、`baseDir` 配下にある画像を参照してUI骨格に反映する
  - 例: Next/Astro/React → `public/design-assets/*`
  - 例: SvelteKit → `static/design-assets/*`
- `components.json` の `slots` や `usedBy` 情報と照合し、画像が必要な箇所（ロゴ/アイコン/イラスト/写真）の取りこぼしを防ぐ
- 画像の最適化（次世代フォーマット変換/圧縮/レスポンシブ画像生成等）は、この工程では必須にしない（まず再現性を優先）

### ゲート
- 見た目一致（主要variantsのプレビュー/Story）
- tokens外の値0件 / Lint/Type green
- ここで停止
