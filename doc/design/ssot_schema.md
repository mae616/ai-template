# デザインSSOT（JSON）スキーマ：tokens / components / context

このドキュメントは、`/design-ssot`（Figma）や `/design-mock`（会話）で生成する **SSOT（Single Source of Truth）** の最低限の形を固定する。

## 目的
- `doc/design/design-tokens.json` / `doc/design/components.json` / `doc/design/design_context.json` を **同じ解釈で**後続へ渡す
- 後続（`/design-html` → `/design-ui` → `/design-components` → `/design-assemble`）の精度と再現性を上げる
- 技術スタックのSSOTは **`doc/rdd.md`** とし、SSOT JSON は可能な限り **スタック非依存**に保つ
- CSSだけでは再現できない **画像アセット**（ロゴ/アイコン/イラスト/写真等）も、可能な限りSSOTとして管理する（後続で参照できるように）

---

## 1) `doc/design/design-tokens.json`（Design Tokens）

### ルール
- **物理値（primitive）** と **意味（semantic）** を混ぜない
- semantic は primitive を参照する（値の重複を避ける）
- 単位を明記する（px/%/rem など）
- CSSで表現できる見た目（例: **背景/枠線/角丸/影/不透明度**）は、可能な限り tokens に落とす（後続の再現性を上げる）
  - 対象例: gradient（グラデ）/ blur（ぼかし）/ blend mode（ブレンド）/ strokeAlign（ストローク位置）
  - blur は **filter（要素自体）** と **backdrop-filter（背景）** を区別して保持する（同じ“ぼかし”でも意味が違うため）
  - strokeAlign（inside/center/outside）は、WebのCSSでは完全一致が難しい場合があるため、**意図としてSSOTに保持**し、後続で近似する（近似時は差分を明記）

### 例（抜粋）

```json
{
  "meta": { "version": 1 },
  "primitives": {
    "color": {
      "gray": { "900": "#111827", "100": "#F3F4F6" },
      "blue": { "600": "#2563EB" }
    },
    "border": {
      "width": { "0": "0px", "1": "1px", "2": "2px" },
      "style": { "solid": "solid" },
      "align": { "inside": "inside", "center": "center", "outside": "outside" }
    },
    "opacity": { "100": 1, "80": 0.8 },
    "gradient": {
      "brand": "linear-gradient(90deg, #2563EB 0%, #7C3AED 100%)"
    },
    "blur": { "sm": "8px", "md": "16px" },
    "blendMode": { "normal": "normal", "multiply": "multiply", "screen": "screen", "overlay": "overlay" },
    "space": { "0": "0px", "1": "4px", "2": "8px", "4": "16px" },
    "radius": { "sm": "6px", "md": "10px" },
    "font": {
      "size": { "sm": "14px", "md": "16px", "lg": "20px" },
      "weight": { "regular": 400, "bold": 700 },
      "lineHeight": { "md": 1.5 }
    },
    "shadow": { "sm": "0 1px 2px rgba(0,0,0,0.08)" },
    "breakpoints": { "sm": "640px", "md": "768px", "lg": "1024px" }
  },
  "semantic": {
    "color": {
      "text": {
        "primary": { "ref": "primitives.color.gray.900" },
        "muted": { "ref": "primitives.color.gray.100" }
      },
      "surface": {
        "page": { "ref": "primitives.color.gray.100" },
        "card": { "ref": "primitives.color.gray.100" }
      },
      "surfaceGradient": {
        "brand": { "ref": "primitives.gradient.brand" }
      },
      "border": {
        "default": { "ref": "primitives.color.gray.900" }
      },
      "brand": {
        "primary": { "ref": "primitives.color.blue.600" }
      }
    },
    "space": {
      "page": { "ref": "primitives.space.4" }
    }
  }
}
```

> 補足: gradient は、スタック非依存の最小形として **CSS文字列**でもよい。  
> ただし、後続でネイティブUI等へ落とす可能性がある場合は、次のような“構造化”表現を併用してもよい（任意）:
>
> ```json
> {
>   "primitives": {
>     "gradientObject": {
>       "brand": {
>         "type": "linear",
>         "angleDeg": 90,
>         "stops": [
>           { "color": "#2563EB", "pos": 0 },
>           { "color": "#7C3AED", "pos": 1 }
>         ]
>       }
>     }
>   }
> }
> ```

---

## 2) `doc/design/components.json`（Components / Variants）

### ルール
- variants は **propsに落とせる粒度**（`size/tone/state` のように実装分岐できる単位）
- “画面固有の見た目”は、まずはコンポーネント化せずレイアウトで持つ（過剰抽象化を避ける）
- border/background/影/角丸など **CSSで表現できる見た目**は、可能な限り tokens を参照して `styles` として残す（後続が再現できるように）
  - `styles` は **実装が復元できる粒度**で残す（例: 背景=塗り/グラデ、枠線=色/太さ/位置、効果=ぼかし/ブレンド）

### コンポーネント命名規約（固定）
- `name` は **PascalCase**（例: `Button`, `PriceCard`, `NavBar`）
- コンポーネントは「見た目」ではなく「役割」で命名する（例: `PrimaryButton` より `Button` + `tone=primary`）
- 画面固有の塊は、まずは layout 側で持つ（`HeroSection` のような命名で乱立させない）

### props/variants キー命名規約（固定）
- variants のキーは **camelCase**（例: `size`, `tone`, `state`, `variant`, `density`）
- キーは「何が変わるか」が一語で分かる語彙に限定する（曖昧な `type` は避ける）

### variant 値（enum値）の命名規約（固定）
- 値は **kebab-case** ではなく、**短い英小文字**（`sm`, `md`, `lg` / `primary`, `secondary`）を推奨  
  - 理由: 生成される型（TS/Swift/Dart等）に落としやすい
- `state` は UIで分岐できる状態だけを列挙する（`default/disabled/loading` を基本に必要なものだけ追加）

### slots 命名規約（固定）
- `slots` は **camelCase**（例: `label`, `iconLeading`, `iconTrailing`）
- slots は「何を差し込むか」で命名し、レイアウト詳細（`leftArea` 等の曖昧語）を避ける

### a11y の最低限（固定）
- コンポーネントがフォーム要素・インタラクションを含む場合、`a11y` に最低限を明記する
  - 例: `role`, `keyboard`, `focusVisible`

### variants 命名規約（固定）
variants のキー名は「意味が通る共通語彙」に固定し、**プロジェクト横断で揃える**。

- **推奨キー（優先順）**
  - `size`: 大きさ（`xs/sm/md/lg/xl`）
  - `tone`: 意味・強調（`primary/secondary/tertiary/danger` 等）
  - `state`: 状態（`default/hover/focus/active/disabled/loading` 等）
  - `variant`: 見た目の型（`solid/outline/ghost` 等、toneで表せない差がある場合のみ）
  - `density`: 密度（`compact/comfortable` 等）
  - `align`: 配置（`left/center/right`）
- **非推奨**
  - `color`（toneとsemantic tokenで表現する）
  - `type`（曖昧。`variant` か `tone` に落とす）

### state の扱い（固定）
- `state` は **UIの分岐**に使う。実装側で表現できるものだけを並べる。
- 推奨セット（必要なものだけ採用）:
  - `default`, `disabled`, `loading`
  - `hover`, `focus`, `active`（Webの疑似クラス/標準状態として扱える場合）

### レスポンシブとvariantsの関係（固定）
- レスポンシブ差分は、原則 **layout/context**（`design_context.json`）側で表現する。
- ただし、同一コンポーネントがブレイクポイントで「別の型」になる場合は、
  - `variant` または `size` に落とす（例: `Card.size=sm|md`）
  - ルール: **propsで説明できないレイアウト差分は、コンポーネント化しない**（layout責務にする）

### 例（抜粋）

```json
{
  "meta": { "version": 1 },
  "components": [
    {
      "name": "Button",
      "description": "主要アクション用ボタン",
      "variants": {
        "size": ["sm", "md", "lg"],
        "tone": ["primary", "secondary"],
        "state": ["default", "disabled", "loading"]
      },
      "defaults": { "size": "md", "tone": "primary", "state": "default" },
      "slots": ["label", "iconLeading", "iconTrailing"],
      "styles": {
        "backgroundColorRef": "semantic.color.brand.primary",
        "backgroundGradientRef": "semantic.color.surfaceGradient.brand",
        "textColorRef": "semantic.color.text.primary",
        "border": {
          "colorRef": "semantic.color.border.default",
          "widthRef": "primitives.border.width.1",
          "styleRef": "primitives.border.style.solid",
          "alignRef": "primitives.border.align.inside"
        },
        "radiusRef": "primitives.radius.md",
        "shadowRef": "primitives.shadow.sm",
        "effects": {
          "blur": {
            "type": "backdrop",
            "amountRef": "primitives.blur.sm"
          },
          "blendModeRef": "primitives.blendMode.normal",
          "opacityRef": "primitives.opacity.80"
        }
      },
      "a11y": {
        "role": "button",
        "keyboard": true,
        "focusVisible": true
      }
    }
  ]
}
```

---

## 3) `doc/design/design_context.json`（Pages / Layout / Constraints）

### ルール
- 画面（page）とレイアウト（frame/section）の階層を持つ
- constraints/resizing（Figma）を、後続がスタック別にマッピングできる形で残す

### constraints/resizing → レスポンシブ対応表（固定）
この対応表は `/design-ui` が実装へ落とすときの基準。

#### constraints（親コンテナに対する固定/伸縮）
- `horizontal: SCALE`
  - Web（Tailwind例）: `w-full` / コンテナ幅に追従
  - レイアウト責務: 横方向に“伸びる”ことを優先
- `horizontal: LEFT_RIGHT`
  - Web: `w-full` + 左右paddingを維持（container/section設計で担保）
- `vertical: TOP_BOTTOM`
  - Web: `h-full`（ただし文脈で不要なら付けない）

#### resizing（要素自身の伸縮特性）
- `horizontal: FILL`
  - Web: `flex-1` / `w-full`（文脈で選択）
- `horizontal: HUG`
  - Web: `inline-flex` / `w-fit`（内容に合わせる）
- `vertical: FILL`
  - Web: `flex-1` / `h-full`（文脈で選択）
- `vertical: HUG`
  - Web: `h-auto`

#### autoLayout（Figma）→ flex/grid（Web）
- `layout.type = autoLayout` & `direction = vertical`
  - Web: `flex flex-col`
- `layout.type = autoLayout` & `direction = horizontal`
  - Web: `flex flex-row`
- `gapTokenRef`
  - Web: tokensに対応する `gap-*`（magic number禁止）
- `paddingTokenRef`
  - Web: tokensに対応する `p-*`（magic number禁止）

#### breakpoints（レスポンシブ）
- breakpoints は `doc/design/design-tokens.json` の `primitives.breakpoints` をSSOTとする
- ブレイクポイントで構造が変わる場合は、まず **layout側**（context）で表現し、props（variants）での分岐は必要時のみ

### 例（抜粋）

```json
{
  "meta": { "version": 1 },
  "pages": [
    {
      "key": "HomePage",
      "frames": [
        {
          "key": "Hero",
          "layout": {
            "type": "autoLayout",
            "direction": "vertical",
            "gapTokenRef": "primitives.space.4",
            "paddingTokenRef": "semantic.space.page"
          },
          "constraints": {
            "horizontal": "SCALE",
            "vertical": "TOP"
          },
          "resizing": { "horizontal": "FILL", "vertical": "HUG" }
        }
      ]
    }
  ]
}
```

---

## 後続コマンドとの関係（重要）
- `/design-html` は上記3ファイルを入力として **スタック非依存HTML** を出す
- `/design-ui` は上記3ファイルを入力として **スタック別の静的骨格** を出す（スタックは `doc/rdd.md` が既定）
- `/design-assemble` は `components.json` の variants を **型付きprops** に落として結合する（スタックは `doc/rdd.md` が既定）

---

## 4) `doc/design/assets/assets.json`（Assets Manifest）

### 目的
- Figma（またはユーザー提供）から取得した画像アセットを `doc/design/assets/` に保存し、どの要素にどの画像を使うかを機械可読で残す
- `/design-html` や `/design-ui` が参照して、画像の取りこぼしを防ぐ

### ルール
- 画像の**実体**は「スタック既定の公開ディレクトリ」（例: `public/` や `static/`）配下へ保存する
- manifestは `doc/` 側に置き、`baseDir` と `files[].path` の組み合わせで参照する（`path` は `baseDir` からの相対）
- “実装依存の最適化”は後工程で行う（ここでは **SSOTとしての対応関係**を優先）

### 例（抜粋）

```json
{
  "meta": { "version": 1 },
  "baseDir": "public/design-assets",
  "assets": [
    {
      "key": "AppLogo",
      "type": "logo",
      "preferredFormat": "svg",
      "files": [
        { "path": "logos/app-logo.svg", "format": "svg", "scale": "1x" }
      ],
      "usedBy": [
        { "component": "NavBar", "slot": "brand" }
      ]
    },
    {
      "key": "HeroImage",
      "type": "image",
      "preferredFormat": "webp",
      "files": [
        { "path": "images/hero@1x.webp", "format": "webp", "scale": "1x" },
        { "path": "images/hero@2x.webp", "format": "webp", "scale": "2x" }
      ],
      "usedBy": [
        { "page": "HomePage", "frame": "Hero" }
      ]
    }
  ]
}
```


