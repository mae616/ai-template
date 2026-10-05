# Figma で測るときの作法

> `design-audit` の手順1・3・4・9を、Figma（Plugin API / `use_figma`）で行うときのコード例と落とし穴。
> ⚠️ API の詳細は Figma 公式（Plugin API リファレンス）を正とする。ここは使い方の型だけ。

## 範囲を条件で絞る（手順1）

```js
// 画面フレームだけを対象にする。名前と実寸の両方で絞り、落ちたものは別に一覧にする
const frames = page.findAllWithCriteria({ types: ["FRAME"] });
const screens = frames.filter(n => /^S\d+/.test(n.name) && [390, 1440].includes(Math.round(n.width)));
const dropped = frames.filter(n => !screens.includes(n) && n.parent?.type === "PAGE");
// 出力に「条件式」と件数を両方書く: 例「名前 ^S\d+ かつ 幅 390/1440 の FRAME ＝ N画面」
```

- 名前の規則（例 `^S\d+`）と幅はプロジェクトの採番規則・画面幅に合わせる
- `dropped` は必ず目で見る（未採番の画面が落ちていないか）

## 分布を出す（手順3）

```js
const dist = {};
for (const n of targets) { const k = Math.round(n.width); dist[k] = (dist[k] || 0) + 1; }
```

## 見えないものを測る（手順4）

| 測るもの | 使うもの | 落とし穴 |
|---|---|---|
| 線画の実寸 | `absoluteRenderBounds`（線の太さを含む） | `width` / `height` は枠の大きさで、中身ではない |
| 実際の余白 | 線画の端 → 隣の要素の端 | `itemSpacing` は枠どうしの間隔 |
| コントラスト | 文字の fill と、**祖先をたどって**見つけた背景の fill | 背景は直接の親に無いことが多い |
| 線幅の割れ | `strokeWeight ÷ 親の枠の大きさ` | 線幅は段ごとに違うので、絶対値で数えると割れが見えない |
| 文字の色・書式 | `getStyledTextSegments` で区間ごとに読む | 1つのテキストの中で値が混在していると `figma.mixed` が返り、単一値の分岐を素通りする |

## 参照の古さを当てる（手順9）

1. リポジトリの Markdown から `123:456` 形式のノード番号を全部抜き出す（履歴の置き場は対象外）
2. 各番号のノードを引き、**親をたどってページ名を特定する**（`getNodeByIdAsync` はページをまたいで引けるので、「いまのページで見つかった＝そのページにある」ではない）
3. 文書に書かれたページ名・画面番号と突き合わせる
4. 1行に複数の番号が書かれていることがあるので、照合は行単位ではなく**近さ（前後数十字）**で結ぶ

出るもの: 実在しない番号／没案・未検証のページのノードを、ページを書かずに指している／書かれたページと実物のページが違う／ノードの画面と、文が語っている画面が違う

## 実装の画面で測るとき

- 測る前に動きを止める（`prefers-reduced-motion` を立てる）。現れのアニメーション中は `transform` が残り、嘘の差が出る
- `margin` も `padding` も正しいのに位置が合わないときは、`transform` を見る
