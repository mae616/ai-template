# デザインSSOT（JSON）スキーマ：tokens / components / context

このドキュメントは、`/design-ssot`（Figma）や `/design-mock`（会話）で生成する **SSOT（Single Source of Truth）** の最低限の形を固定する。

## 目的
- `doc/design/design-tokens.json` / `doc/design/components.json` / `doc/design/design_context.json` を **同じ解釈で**後続へ渡す
- 後続（`/design-html` → `/design-ui` → `/design-components` → `/design-assemble`）の精度と再現性を上げる
- 技術スタックのSSOTは **`doc/rdd.md`** とし、SSOT JSON は可能な限り **スタック非依存**に保つ

---

## 1) `doc/design/design-tokens.json`（Design Tokens）

### ルール
- **物理値（primitive）** と **意味（semantic）** を混ぜない
- semantic は primitive を参照する（値の重複を避ける）
- 単位を明記する（px/%/rem など）

### 例（抜粋）

```json
{
  "meta": { "version": 1 },
  "primitives": {
    "color": {
      "gray": { "900": "#111827", "100": "#F3F4F6" },
      "blue": { "600": "#2563EB" }
    },
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

---

## 2) `doc/design/components.json`（Components / Variants）

### ルール
- variants は **propsに落とせる粒度**（`size/tone/state` のように実装分岐できる単位）
- “画面固有の見た目”は、まずはコンポーネント化せずレイアウトで持つ（過剰抽象化を避ける）

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


