# [デザイン] 1. SSOT（tokens/components/context）を生成（Figmaルート）

## コマンド: /design-ssot $FIGMA_REF
Figma MCPから設計情報を抽出し、AI/人間が参照するSSOTを作る。**実装はしない**。

## 共通前提（参照）
- 口調・出力規約・差分出力の方針は `CLAUDE.md` に従う。
- `doc/rdd.md` を読み、該当する `.claude/skills/*` を適用して判断軸を揃える（例: `ui-designer` / `usability-psychologist`）。
- 詳細運用（サンプル運用/依存評価補助/ADR-lite）は `doc/ai_guidelines.md` を参照。

### 入力
- $FIGMA_REF: Figmaファイル/ページ識別子（MCPが認識できる指定）

### 出力（差分のみ）
- doc/design/design_context.json   # 画面/レイアウト/constraints/resizing
- doc/design/design-tokens.json    # 色/タイポ/spacing/半径/影/枠線/不透明度/breakpoints（単位明記）
- doc/design/components.json       # 主要コンポーネント + variants（例: size/tone/state）
- (スタック既定の置き場)/design-assets/  # 画像アセット（Figmaからexportして保存）
- doc/design/assets/assets.json          # 画像アセットのmanifest（どの要素がどのファイルに対応するか）

### ルール
- JSONは**単位明記**（px/%/unitless）
- tokens は「物理値」と「semantic（意味）」を混ぜない（例: `color.gray.900` と `color.text.primary` を分け、semanticは物理へ参照する）
- variants は **props/属性に落とせる粒度**（例: { size:["sm","md","lg"] }）
- **CSSで指定できる見た目は可能な限りSSOT化する**（後続の再現性を上げる）
  - 例: background（塗り/グラデ）/ border（stroke: 色・太さ・style・位置）/ radius / shadow / opacity / blur / blend mode
  - blur は **filter（要素自体）** と **backdrop-filter（背景）** を区別してSSOTに残す
  - 取りこぼしやすい: 「枠線だけある」「背景だけある」「hoverだけ変わる」など
- `components.json` には、可能な限り `styles`（background/border/radius/shadow/textColor など）を tokens 参照で残す（値の直書き禁止）
- **RDD遵守**（doc/rdd.md のスタック/制約に反しない）
- 技術スタックの既定は `doc/rdd.md`。このコマンドの出力（SSOT JSON）は可能な限りスタック非依存に保ち、後続（`/design-ui` / `/design-assemble`）が `doc/rdd.md` を参照して生成する。
- SSOTの最低限スキーマは `doc/design/ssot_schema.md` を参照。
- `doc/design/components.json` の variants 命名規約は `doc/design/ssot_schema.md` に従い、プロジェクト横断で揃える。
- 画像（アイコン/ロゴ/イラスト/写真など）で **CSSだけでは再現できないもの**は、可能な限りFigmaからexportして「スタック既定の置き場」に保存し、`assets.json` に対応関係を残す
- ここで停止

### ゲート
- tokens/variantsに未定義値なし
- design_context.json に constraints/resizing が含まれる
- components.json のvariantsが「実装の分岐」に落とせる粒度になっている
- border/background/gradient/blur/blend/strokeAlign が存在する要素について、tokens と components の `styles` 参照に落ちている（取りこぼし0）
- 画像アセットが必要な箇所（ロゴ/アイコン/イラスト/写真）が `doc/design/assets/` と `assets.json` に落ちている（取りこぼし0）
 - 画像アセットが必要な箇所（ロゴ/アイコン/イラスト/写真）が「スタック既定の置き場」 と `assets.json` に落ちている（取りこぼし0）

### 画像アセットの扱い（重要）
#### アセットの保存先（スタック既定）
`doc/rdd.md` の技術スタックに合わせて、アセット実体は以下へ保存する（SSOTのmanifestは `doc/` に残す）：
- Next.js / React / Astro: `public/design-assets/`
- SvelteKit: `static/design-assets/`
- （判定できない場合）: まず `public/` があれば `public/design-assets/`、なければ `static/design-assets/`

- **優先形式**
  - アイコン/ロゴ: SVG（可能なら単色・パス化）
  - 写真/ラスタ: WebP または PNG（透過が必要ならPNG）
  - 複雑なイラスト: SVG優先、無理ならPNG
- **命名**
  - `doc/design/assets/{kind}/{name}@{scale}.{ext}` を基本（例: `icons/search@1x.svg`, `images/hero@2x.webp`）
  - `name` は英小文字 + `-`（kebab-case）で安定させる

### ダウンロードできない場合（ユーザーにお願いする手順）
Figma側の状態によっては、MCPが画像を取り出せないことがあります。次をユーザーに確認・依頼する：
1. **対象レイヤー/フレームを export 可能にする**
   - Figma右パネルの **Export** を追加し、形式（SVG/PNG等）と倍率（1x/2x等）を設定する
2. **権限の確認**
   - そのFigmaファイルにアクセス権があるか（閲覧のみでexportが制限されていないか）
3. **画像の代替入力**
   - どうしてもMCPで取得できない場合は、ユーザーに「SVG/PNG/WebPを手元からアップロード」または「アセットの配布方法（zip等）を提示」してもらい、`doc/design/assets/` に配置してもらう
