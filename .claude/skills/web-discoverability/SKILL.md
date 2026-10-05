---
name: web-discoverability
user-invocable: true
description: "Web のプロジェクトで、検索エンジン・SNS・AI クローラーへの見え方を設定する。OGP と SEO の基本（Google 公式ガイドライン）を必ず入れ、検索に出すか／AI の学習に使わせるか／AI の検索・回答に出すか／出さないページ（/setup で聞く）と、利用者の操作で来る AI を塞ぐか・本番の URL（初回に聞く）の答えから、robots.txt・noindex・meta を設定して数えて照合する。Web のページを作るとき・公開前・ページを足したときに使う。"
---

# web-discoverability — 検索・SNS・AI への見え方を、答えから設定する

## このスキルが解く問題

公開範囲の設定は、作っている途中では誰も気にせず、公開したあとで「検索に出ない」「出したくないページが出た」「AI の学習に使われていた」と気づく。しかも仕組みが紛らわしい（robots.txt で塞ぐと noindex が読まれない、AI のボットは学習用と検索用で分かれている）。
このスキルは、**公開範囲を人間の答えとして先に決め、その答えから設定を機械的に作り、ページごとに数えて照合する**。

## 発火条件

- Web のプロジェクトでページを作るとき（F4 の実装で、ページごとに）
- 公開の前
- ページ・サブドメインを足したとき

Web 以外（ネイティブアプリ・CLI 等）では使わない。

## 入力: 公開範囲の答え

rdd の事実ブロック「運用環境」の **Web の公開範囲** を読む。1〜4 は `/setup` が聞いて書く。5・6 はこのスキルが初めて使われたときに聞き、同じ行に書く（書く文面を見せて合意を取る）。答えは別々に持ち、1つにまとめない（各社でボットが分かれているため）。

| # | 項目 | 何を決めるか |
|---|---|---|
| 1 | 検索 | 検索エンジンに出すか |
| 2 | AI の学習 | 生成 AI の学習に使わせるか（効くのは下の表の会社だけ。Google・Anthropic は**今後の分だけ**と明記、OpenAI は記載なし。聞くときにこの範囲を伝える） |
| 3 | AI の検索・回答 | AI の検索機能・回答に出すか |
| 4 | 出さないページ | 検索に出さないページ（管理画面・下書き・ステージング等）。AI からも外すか |
| 5 | 利用者の操作で来る AI | 利用者が URL を渡して質問したときに、AI が読みに来るのを塞ぐか |
| 6 | 本番の URL | canonical・og:url の元になる URL（サブドメインごと） |

- ⚠️ 未記入を「出す」「出さない」のどちらにも読み替えない。**決めていないものは推測で埋めず、止まって聞く**
- **自律ループの中（`auto-design` 手順5.5 など）では止まらない**（ここが正。呼び出し元はここを参照する）:
  - 決めていない項目は、その項目に当たる robots.txt・noindex を**書かない**（推測で塞がない・開けない）。「必ず入れるもの」（title・description・canonical・OGP）は入れる。ただし本番の URL（6）が決まっていなければ、canonical・og:url は書かずに未決の一覧に載せる（URL を推測しない）
  - 未決の置き場は rdd の「Web の公開範囲」の行そのもの（未記入＝決めていない）。照合の結果に「未決の項目」の一覧を必ず書き、呼び出し元の最後の報告（`auto-design` 手順9・`auto-build` のエビデンスレポートの「判断待ち」）に載せる
  - ⚠️ 公開（本番への配置）の前には必ず人間が答える。未決のまま公開しない（「出さないページ」が未決なら、管理画面などが検索に出るおそれがある）。照合する時点: sprint → main の PR 本文に「Web の公開範囲の未決: n件（項目名）」を必ず書き、人間がマージを判断するときに見る（PR を作る経路を問わない。決まりの正は `auto-task` の「5. Sprint 完了検知」）
- 答えどうしが食い違うとき（例: 検索に出さない＝noindex なのに、Google の AI 機能には出す）は、止まって聞く。自律ループの中では止まらず、食い違う項目どうしを両方とも「決めていない」と同じに扱う（上の決まり）
- **設定では叶えられない答え**がある（下の表で「止める手段が無い」と書いたもの）。そのときはトレードオフを説明して聞き直す。黙って「何もしない」で済ませない

## 必ず入れるもの（答えに関係なく、全ページ）

出典: 末尾の「出典」の 1・2。

| 何を | 決まり |
|---|---|
| `<title>` | ページごとに固有で、短く、内容を正しく表す |
| `<meta name="description">` | ページごとに固有の短い要約 |
| URL | 内容を表す語を使う。似たページはディレクトリでまとめる |
| canonical | 同じ内容に複数の URL があるときは、リダイレクトか `rel="canonical"` で正の URL を1つにする |
| 画像の alt | 画像と内容の関係を説明する |
| OGP（必須4つ） | `og:title` / `og:type` / `og:image` / `og:url`（`og:url` は canonical と同じ URL） |
| OGP（任意。このテンプレートでは入れる） | `og:description` / `og:site_name` / `og:locale` / `og:image:width`・`og:image:height`。`og:image` を入れたら `og:image:alt` も入れる（ogp.me が「入れるべき」と書いている） |

- 値は直書きせず、値のファイルから引く（形は `doc/input/design/ssot_schema.md` に従う）
  - 文言（`copy.json` の copyKey）: サイト全体は `site.name`・`site.description`・`site.ogImageAlt`、ページごとは `<ページキー>.meta.title`・`.meta.description`・`.meta.ogImageAlt`
  - OGP 画像（`assets.json`）: `assets[]` の中の `key: "SiteOgImage"` の項目。URL は `baseDir` と `files[].path` から作る。ページごとに変えるときは、ページキーの先頭を大文字にして `OgImage` を続ける（例: `HomePageOgImage`）。`og:image:width`・`height` は画像ファイルの実寸を測って入れる
  - `og:locale`: `copy.json` の `defaultLocale` を `_` 区切りに変えて使う（例: `ja-JP` → `ja_JP`）
  - `og:type`: 既定は `website`。記事など別の型にするページは聞く
- 値が無いときは作らない。その値のファイルの `undecided` に足す文面を見せて合意を取り、止まって聞く。自律ループの中では止まらず、値のファイルに仮の値を置く例外（`.claude/rules/dev-practices.md`「一時と確定を分ける」）に従い、仮の値で入れて印と `undecided` を付けて進む
- 実装はフレームワークの標準の仕組み（メタデータ API 等）で書く。手で `<head>` を組み立てる仕組みを自作しない
- `meta keywords` は入れない（Google は使っていない）
- 構造化データ・サイトマップは任意。入れるかは人間に聞く（構造化データは検索結果の特別な表示の対象になる。サイトマップは必須ではない）

## 答えから作る設定

出典: 末尾の「出典」の 3〜8。

### 検索
| 答え | 設定 |
|---|---|
| 出す | 何もしない（塞がない） |
| 出さない（サイト全体） | 全ページに `<meta name="robots" content="noindex">`、または HTTP ヘッダー `X-Robots-Tag: noindex` |

### 出さないページ
- そのページに `noindex`（meta か `X-Robots-Tag`）を付ける
- AI のボットの制御について、各社は robots.txt で行うと書いている（noindex には触れていない）。AI からも外すと答えたときは、**そのボットの `User-agent` に限って**そのページを `Disallow` する（Googlebot は塞がない。塞ぐと noindex が読まれない）
- ⚠️ **noindex を付けたページを robots.txt で塞がない**。塞ぐとクローラーが noindex を読めず、ほかのページからのリンク経由で検索に出ることがある
- ログインが要るページは、noindex より先に認証で守る（noindex は秘密を守る仕組みではない）

### AI の学習・AI の検索・利用者の操作で来る AI
robots.txt の `User-agent` ごとに書く。学習と検索は別のボット。表の「止めたときに起きること」は各社の原文の言い方に合わせてある（「出にくくなる」を「出なくなる」と言い換えない）。

| 会社 | 答え | 止めるもの | 止めたときに起きること |
|---|---|---|---|
| Google | 学習 | `Google-Extended` | Gemini の学習とグラウンディングに使われなくなる。**Google 検索への掲載と順位には影響しない** |
| Google | AI の検索・回答 | **止める手段が無い**（AI Overviews 等は検索に組み込まれていて、Googlebot が兼ねる） | 絞るなら `nosnippet`・`data-nosnippet`・`max-snippet`・`noindex` で、**通常の検索結果の表示も一緒に変わる**。人間にこのトレードオフを説明して聞き直す |
| Google | 利用者の操作 | **robots.txt では止まらない**（利用者の操作で来るフェッチャーは、たいてい robots.txt を無視する） | — |
| OpenAI | 学習 | `GPTBot` | 生成 AI の基盤モデルの学習に使わないという合図になる |
| OpenAI | AI の検索・回答 | `OAI-SearchBot` | ChatGPT の検索の回答には出なくなる。**案内用のリンクとしては出ることがある** |
| OpenAI | 利用者の操作 | `ChatGPT-User` | **robots.txt が効かない場合がある**（利用者の操作で来るため） |
| Anthropic | 学習 | `ClaudeBot` | 学習用の収集から外れる |
| Anthropic | AI の検索・回答 | `Claude-SearchBot` | 検索用に取り込まれなくなり、**検索で出にくくなる**（出なくなる保証はない） |
| Anthropic | 利用者の操作 | `Claude-User` | 利用者の質問に応じて読みに来なくなり、**利用者の検索で出にくくなる** |

- 塞ぐときは `User-agent: <名前>` と `Disallow: /` を組で書く
- **サブドメインごとに robots.txt が要る**（Anthropic のヘルプが「出したくないサブドメインごとに行う」と明記）
- 5（利用者の操作で来る AI）を聞くときは、塞いでも止まらないものがある（Google・OpenAI）ことと、塞ぐと利用者が URL を渡しても読まれにくくなることを、先に伝える
- ここに無い会社のボットは推測で足さない。足すときは、その会社の公式ドキュメントで名前と用途を確かめ、出典を書く

## 照合する（数えるレビュー）

作ったら、ページごとに実物を数える（`design-audit` と同じ考え方。書いた設定ではなく、配信された HTML とヘッダーを見る）。

1. 全ページの一覧を作る（ルーティングの定義、またはサイトマップから）
2. ページごとに数える: `<title>`・description・canonical・OGP 必須4つ・`og:image:alt` の有無、title と description の重複。**OGP は配信された HTML（JS を実行しない取得）で見る**（SNS のクローラーの多くは JS を実行しない）。title と description は描画後の DOM でも確かめる
3. 出さないページに `noindex` があるか（meta か `X-Robots-Tag`）。そのページが robots.txt で塞がれていないか
4. robots.txt を取得し、答えと突き合わせる（サブドメインごと）
5. 決めていない項目に当たる設定は、外れに数えず「未決の項目」として別に一覧にする
6. 外れが0件になるまで直す。**「1件は外れる入力」と「1件も外れない入力」の両方で照合の仕組み自体を動かしてから**数える（`.claude/rules/tool-usage.md`）

## 出典（2026-10-02 確認。書き換える前に読み直す）

1. Google SEO スターターガイド（最終更新 2025-12-10）— https://developers.google.com/search/docs/fundamentals/seo-starter-guide
2. The Open Graph protocol — https://ogp.me/
3. Google: noindex でインデックス登録をブロックする（最終更新 2025-12-10）— https://developers.google.com/search/docs/crawling-indexing/block-indexing
4. Google: 一般的なクローラー（Google-Extended。最終更新 2026-07-14）— https://developers.google.com/crawling/docs/crawlers-fetchers/google-common-crawlers
5. OpenAI: クローラーとユーザーエージェント — https://developers.openai.com/api/docs/bots
6. Anthropic ヘルプ: ClaudeBot / Claude-User / Claude-SearchBot（最終更新 2026-04-07）— https://support.claude.com/en/articles/8896518
7. Google: AI 機能とウェブサイト（AI Overviews の制御。最終更新 2025-12-10）— https://developers.google.com/search/docs/appearance/ai-features
8. Google: 利用者の操作で来るフェッチャー（最終更新 2026-08-19）— https://developers.google.com/crawling/docs/crawlers-fetchers/google-user-triggered-fetchers

## やってはいけない
- 公開範囲の答えが無いのに、既定値で robots.txt や noindex を書く
- noindex のページを robots.txt で塞ぐ
- 「AI に使わせない」を1行の設定にまとめる（学習と検索は別のボット）
- 出典を確かめていないボット名を足す
- noindex を秘密の保護に使う

## 次の一手
- **次に効くこと**: {外れが残ったページ、または人間に聞くべき未決の項目を1つ}
- **引き継ぎの自信度**: (1-10) — この出力だけで、次の人が残りを直せるか
- ⚠️ この欄に失敗の一覧を書かない（書くのは「次にどうするか」）
