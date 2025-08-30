# [デザイン] 4. RDD準拠の技術スタックに結合するアダプタ層を生成。  

## コマンド: /design-bind [$TARGET]
`design/components.json` の variants を **型付きProps/属性** にマッピングし、選択スタックへ**結合（再利用可能UI）**するアダプタ層。  
既定は doc/rdd.md の技術スタック。引数で変更する際は **ADR-lite承認必須**。

### 入力
- $TARGET（任意）: react | vue | svelte | swiftui | flutter | web-components | plain-html …

### 出力（差分のみ）
- スタック別の再利用UI
  - React: `src/components/{Name}.tsx`（Props型: size/tone/state…）, `src/stories/*`, `__tests__/*`
  - Vue: `src/components/{Name}.vue`（props + Story）
  - Svelte: `src/lib/{Name}.svelte`（props + Story）
  - SwiftUI: `Sources/UI/{Name}.swift`（case/enumでvariants）
  - Flutter: `lib/widgets/{name}.dart`（enum/Theme拡張）
  - Web Components: `src/components/{name}.ts`（attrs/reflect + CSS Custom Props）
- すべて **差分リファクタ**（skeleton → 再利用化）。仕様追加禁止。

### マッピング規約（例）
- variants.size → props.size（"sm"|"md"|"lg"）/ enum 等
- variants.tone → tokensのsemantic colorキーにバインド
- state（hover/disabled） → スタック標準のstate表現
- Docコメント（JSDoc/Docstring/Swift Doc/ Dartdoc）必須

### ルール
- **RDD準拠/SOLID**。逸脱は ADR-lite で理由と影響を明記
- Lint/Type/Test/Story すべて緑
- ここで停止

### ゲート
- Storybook/Preview で全variants表示OK
- Lint/Type/Test green（対応スタックのみ）
