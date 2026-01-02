# [デザイン] （任意）SSOT → 静的HTML を生成し、`doc/design/html/` に保存

## コマンド: /design-html [$PAGE_KEY]
設計JSON（SSOT）から**静的HTML**を生成し、`doc/design/html/` に保存する。

## いつ使う？（位置づけ）
- **ドキュメント共有/レビュー用**に「ブラウザで見られる見た目」が欲しいとき
- 実装スタックに依存しない形で、UIの骨格・トークン反映を目視確認したいとき
- `/design-ssot` または `/design-mock` で SSOT が揃っている前提（このコマンドはSSOTを作らない）

## 次に何をする？
- 見た目の調整が必要なら、HTMLの差分/変更点を根拠に SSOT（tokens/components/context）へ反映する
- 実装に進むなら `/design-ui` → `/design-components` → `/design-assemble`（READMEのフローに合流）

## 共通前提（参照）
- 口調・出力規約・差分出力の方針は `CLAUDE.md` に従う。
- `doc/rdd.md` を読み、該当する `.claude/skills/*` を適用して判断軸を揃える（例: `ui-designer` / `usability-psychologist` / `tailwind`）。
- 詳細運用（ADR-lite/差分/サンプル運用等）は `doc/ai_guidelines.md` を参照。

### 入力
- $PAGE_KEY（任意）: 画面キー（省略時は主要画面）

### 出力（差分のみ）
- `doc/design/html/{page}.html`（tokens/variants反映、外部依存なしで再現）

### 仕様
- 入力となるJSON（`doc/design/design-tokens.json`, `doc/design/components.json`, `doc/design/design_context.json`）が存在する前提（通常は `/design-ssot` の成果物）
- `doc/design/assets/assets.json` が存在する場合は必ず参照し、画像アセットを反映する（baseDir配下の相対パス）
- React/Vue 等の実装に依存しない生成
- 画像は相対またはデータURIで完結
- **RDD準拠**のスタイルのみ（tokens必須）
- ここで停止

### ゲート
- 主要ブレイクポイントでレイアウト崩れなし（簡易スナップ）
- tokens外の値（magic number）が混入していない
