# [デザイン] 3. JSONから 静的HTML を生成し、`doc/design/html/` に保存  

## コマンド: /design-export-html [$PAGE_KEY]
設計JSONから**静的HTML**を生成し、ドキュメント配布可能な形で保存。

### 入力
- $PAGE_KEY（任意）: 画面キー（省略時は主要画面）

### 出力（差分のみ）
- `doc/design/html/{page}.html`（tokens/variants反映、外部依存なしで再現）

### 仕様
- React/Vue 等の実装に依存しない生成
- 画像は相対またはデータURIで完結
- **RDD準拠**のスタイルのみ（tokens必須）
- ここで停止

### ゲート
- 主要ブレイクポイントでレイアウト崩れなし（簡易スナップ）
