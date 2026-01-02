# [デザイン] 1.（Figma起点）SSOT（tokens/components/context/assets）を生成

## コマンド: /design-ssot $FIGMA_REF
Figma MCPから設計情報を抽出し、AI/人間が参照するSSOTを作る。**実装はしない**。

## いつ使う？（位置づけ）
- Figma（Dev Mode）を根拠に、後続でブレない **SSOT（tokens/components/context/assets）** を確立したいとき
- 会話起点なら `/design-mock`、Figma起点ならこの `/design-ssot` から始める

## 次に何をする？
- 実装に進む → `/design-ui` → `/design-components` → `/design-assemble`
- ドキュメント/共有用の静的HTMLが欲しい → `/design-html`（任意）

## 共通前提（参照）
- 口調・出力規約・差分出力の方針は `CLAUDE.md` に従う。
- `doc/rdd.md` を読み、該当する `.claude/skills/*` を適用して判断軸を揃える（例: `ui-designer` / `usability-psychologist`）。
- 詳細運用（サンプル運用/依存評価補助/ADR-lite）は `doc/ai_guidelines.md` を参照。

## 見た目の基準（ビューポート）について
- まず `doc/rdd.md` の「ターゲット表示環境（事実）」を参照し、**そのビューポートを基準**にSSOTを作る
- 未記入の場合は、以下を **推奨デフォルト**として仮置きし、出力やレビューの前提に明記する：
  - desktop: 1440x900
  - mobile: 390x844
  - tablet: 834x1194

## 事前チェック（必須）：Figma MCPが「使える」状態か
`/design-ssot` は **Figma MCPが利用可能であることが前提**。最初に必ず以下を確認してから進める。

### 1) Claude Code側：MCP登録の確認
- `claude mcp list` を確認し、`figma` が登録されていること

### 2) 接続先：Figma MCP（Dev Mode）の到達確認
- DevContainerからは通常 `http://host.docker.internal:3845/mcp`（環境によっては `host.containers.internal`）に到達する
- 到達できない場合は、**MCPが未起動/未設定/権限不足**の可能性が高い（推測でSSOT生成を続けない）

### 3) うまくいかないとき（ユーザーにお願いする手順）
AI側で「MCPが無い/設定されていない」など見当違いな推測をしないために、まず以下をユーザーに依頼する：
1. **Figma Desktop アプリで Dev Mode / MCP サーバーを有効化**する（Figma公式手順に従う）
2. **DevContainerを再起動**する（`postCreateCommand` の `.devcontainer/setup.sh` が `claude mcp add --transport http figma ...` を実行する前提）
3. それでもダメなら、ユーザーに以下を確認してもらう：
   - 3845番ポートが開いているか（Figma側のMCPが起動しているか）
   - URLが環境と合っているか（`host.docker.internal` / `host.containers.internal`）
   - 必要なら `FIGMA_MCP_URL` を明示して再セットアップする

### 4) DevContainer以外で使う場合（ローカル実行/別コンテナ）
DevContainerを使わない場合は「自動登録」が効かないため、次を前提として扱う：
- **前提**
  - Figma Desktop 側で Dev Mode / MCP サーバーが有効で、MCPが起動していること
  - Claude Code（CLI）を実行する環境から、そのMCPのHTTPエンドポイントに到達できること
- **手順（最小）**
  1. `claude mcp list` を確認し、`figma` が無ければ登録する
     - 例: `claude mcp add --transport http figma "<FIGMA_MCP_URL>"`
  2. `FIGMA_MCP_URL` を環境に合わせて決める（例: `http://host.docker.internal:3845/mcp`）
     - コンテナ→ホストの到達名は環境依存（Docker: `host.docker.internal` / Podman: `host.containers.internal`）
  3. 到達できない場合は、ユーザーに「Figma側のMCP起動・権限・ポート・URL」を確認してもらう（推測で先に進めない）

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
- 画像アセットが必要な箇所（ロゴ/アイコン/イラスト/写真）が「スタック既定の置き場」 と `doc/design/assets/assets.json` に落ちている（取りこぼし0）

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
