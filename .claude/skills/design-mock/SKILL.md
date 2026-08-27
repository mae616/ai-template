---
user-invocable: true
description: "会話からデザインSSOT（JSON）と静的HTML叩き台を同時に生成する。画面デザインの初期検討、UIの方向性を素早く形にしたいときに使う。"
---

# [デザイン] 1.（会話起点）SSOT + 静的HTML（叩き台）を生成

## 入力: $ARGUMENTS（任意）
- 画面キー（複数可。固定命名）（例: `HomePage`, `PricingPage`, `LoginPage`）
- 画面の用途/要件（任意。箇条書きでもOK）

### 複数ページ指定（固定）
- `HomePage PricingPage LoginPage` のように **ページキーを羅列**する
- 省略時は `HomePage` として扱う（単一ページの叩き台）

### ページキー（PageKey）のルール（固定）
- `PascalCase`（例: `HomePage`, `PricingPage`, `LoginPage`）
- 後工程（`/design-html` / `/design-ui`）のページ選択キーになるため、URLやFigma名に依存せず安定させる

## 前提（叩き台を作る前に必ず確認）

- **`doc/input/rdd.md` を読み込む**: ターゲット表示環境・技術スタック・制約を叩き台の前提にする。実装判断に必要な項目が**未記入なら推測で埋めず短問で確認**し、回答を rdd.md に反映してから進む（⚠️ **書き込む文面を見せて合意を得てから書く**。会話での一言を、AIが作った文面のまま要件として定着させない）（rdd.md 自体が無い場合も同様に、必要最小限の事実を質問して起票する）
- **`project-design-language` を読み込む**: 基本方針（誰のため/北極星/単一メタファー）と固有値レジストリを、トーン・情報設計・見た目の判断の前提にする
  - **雛形のまま**（基本方針が `{...}` / TBD）なら、`judgment-harness` の発酵ループに従い、**基本方針だけを質問して人間と埋めてから**叩き台を作る（固有値レジストリは TBD のままでよい。叩き台での調整結果を反映していく）
- **`art-direction` を読み込む**: HTMLを描く直前に**AD宣言**（コンセプト導出線/材質/禁色/効果の序列/禁止則/シグネチャ表現）を出す
- **描画は `design-drafter` サブエージェント**（`.claude/agents/design-drafter.md`。デザイナー人格）に委譲する: AD宣言・要件・SSOTパスを渡し、**①情報設計（ワイヤー宣言）→②ビジュアル**の2段で描かせる（エンジニア文脈のまま描くと等価な箱の羅列・余り物の余白に回帰する。実測済み）
- 描画後は `design-critique` の批評ループ（文脈遮断・must-fix 0まで）を通してから提示する。修正も design-drafter に差し戻す（違和感リストを渡し、ワイヤー宣言から見直させる）

## いつ使う？（位置づけ）
- Figmaが無い/固まっていない状態で、まず叩き台を作って会話で詰めたいとき
- 「静的HTMLで目視」しながら調整し、その根拠を **SSOT（tokens/components/context）** に反映して後続へ合流したいとき

## 次に何をする？
- ページ単位のHTMLでイメージ確認したい → `/design-html`（SSOTからページ単位HTML生成）
- 実装に進む → `/design-ui` → `/design-components` → `/design-assemble`

---

## 🎯 目的
- ユーザーとの会話（要件/トーン/主要導線）から、**ページ単位の静的HTML（複数可）**を生成する
- 実装（状態/データ取得/ルーティング）は入れず、**見た目と情報設計**に集中する
- 以降の共通ルート（`/design-ui` 等）へ合流できるよう、**SSOT（design JSON）も同時に用意**する
- 生成したHTMLは、**ユーザーが目で見ながら調整するためのプレビュー**として扱う（調整点は会話で共有し、SSOT（JSON）側にも反映する）

---

## 見た目の基準（ビューポート）について
- まず `doc/input/rdd.md` の「ターゲット表示環境（事実）」を参照し、**そのビューポートを基準**に叩き台（HTML/SSOT）を作る
- 未記入の場合は、まず**短問で確認して回答を rdd.md に反映（**書き込む文面を見せて合意を得てから書く**）**する。すぐに確認できない場合のみ、以下を **推奨デフォルト**として仮置きし、出力やレビューの前提に明記する：
  - desktop: 1440x900
  - mobile: 390x844
  - tablet: 834x1194

---

## 仕様
- 出力は **静的HTML**（外部依存なしが基本）
- `doc/input/design/html/` に保存
  - 単一ページ: `doc/input/design/html/mock.html` を生成（叩き台）
  - 複数ページ: `doc/input/design/html/{page}.html` をページ数分生成（既定）
- 併せて、以下のSSOTを生成/更新する（Figmaルートと同じ合流点。**複数ページ対応**）
  - `doc/input/design/design_context.json`
  - `doc/input/design/design-tokens.json`
  - `doc/input/design/components.json`
  - `doc/input/design/copy.json`（文言のSSOT。一字一句固定。言い換え禁止）
  - `doc/input/design/assets/assets.json`（画像/動画等のアセットmanifest。取得できない場合は `status:"failed"` を記録して停止）
- 技術スタックは **`doc/input/rdd.md`** をSSOTとして扱う（ここで勝手に変えない）
- `doc/input/design/components.json` の variants 命名規約は `doc/input/design/ssot_schema.md` を参照し、プロジェクト横断で揃える
- ここで停止（次工程は `/design-html` でページ単位イメージ確認、または `/design-ui` で実装フローへ）

### 複数ページ時のSSOT規約（固定）
- `design_context.json.pages[]` を **PageKey単位**で生成する（ページ同士を混ぜない）
- `copy.json` の `copyKey` は **ページキーで名前空間を切る**（例: `homePage.hero.title`）
- `assets.json` の `assetKey` は **ページ横断で一意**（衝突は停止）
- tokens がページで矛盾する場合は **停止**し、ユーザーに命名/設計の合意を依頼する（推測でマージしない）

---

## 反復（重要）
- ユーザーが `doc/input/design/html/*.html` を手で編集して調整した場合は、**差分（diff）または変更点の箇条書き**を入力として受け取る（状況で使い分けOK）
- その調整内容を根拠に、**HTMLだけでなくSSOT（`design-tokens.json` / `components.json` / `design_context.json`）も同時に更新**する
- 文言の調整が入った場合は、**必ず `copy.json` も同時に更新**する（後続で一字一句の再現を担保するため）
- SSOTが古いままだと、後続（`/design-ui` / `/design-components` / `/design-assemble`）で不整合が出るため、**HTML単独修正で終わらせない**

---

## ゲート
- 主要ブレイクポイントで破綻しない（簡易でOK）
- 情報設計（見出し/導線/主要CTA）が説明できる
- `design-critique` の批評ループを通過している（レンダリング→文脈遮断批評→修正を must-fix 0 まで、最大3周）。最終の違和感リスト・vログをAD宣言と併せて提示に添える
- SSOT（tokens/components/context）が矛盾なく、`/design-ui` が実行できる状態になっている
- `copy.json` に未定義文言なし（参照される `copyKey` の不足0件）
- CSSで指定できる見た目（background/border/gradient/blur/blend/strokeAlign）が、SSOT（tokens/componentsのstyles参照）に落ちている（取りこぼし0）
- 画像アセットが必要な箇所（ロゴ/アイコン/イラスト/写真）が `doc/input/design/assets/assets.json` に定義され、`baseDir` 配下に配置されている（取りこぼし0）
  - `assets.json` に `status: "failed"` が1件でもある場合は、**必ずユーザーに失敗理由と次アクション**（手元提供/代替ファイル/Export設定）を明示して停止する

---

## 次に推奨
→ `/design-ui` でSSOT → 静的UI骨格を生成
