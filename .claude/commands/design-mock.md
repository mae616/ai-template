# [デザイン] ルート1: 会話から1枚ペラの静的HTMLを生成（SSOTも同時に用意）

## 入力: $ARGUMENTS（任意）
- 画面名/用途（例: `HomePage`, `Pricing`, `Login`）

---

## 🎯 目的
- ユーザーとの会話（要件/トーン/主要導線）から、**1枚ペラの静的HTML**を生成する
- 実装（状態/データ取得/ルーティング）は入れず、**見た目と情報設計**に集中する
- 以降の共通ルート（`/design-ui` 等）へ合流できるよう、**SSOT（design JSON）も同時に用意**する
- 生成したHTMLは、**ユーザーが目で見ながら調整するためのプレビュー**として扱う（調整点は会話で共有し、SSOT（JSON）側にも反映する）

---

## 共通前提（参照）
- 口調・出力規約は `CLAUDE.md` に従う。
- プロジェクト固有の事実は `doc/rdd.md`（先頭のAI用事実ブロック）を参照する。
- 判断軸は `.claude/skills/*` を適用する（例: `ui-designer` / `usability-psychologist` / `tailwind` / `creative-coder`）。

---

## 仕様
- 出力は **静的HTML**（外部依存なしが基本）
- `doc/design/html/` に保存（例: `doc/design/html/mock.html` または `doc/design/html/{page}.html`）
- 併せて、以下のSSOTを生成/更新する（Figmaルートと同じ合流点）
  - `doc/design/design_context.json`
  - `doc/design/design-tokens.json`
  - `doc/design/components.json`
- 技術スタックは **`doc/rdd.md`** をSSOTとして扱う（ここで勝手に変えない）
- `doc/design/components.json` の variants 命名規約は `doc/design/ssot_schema.md` を参照し、プロジェクト横断で揃える
- ここで停止（次工程は `/design-split` → `/design-ui`）

---

## 反復（重要）
- ユーザーが `doc/design/html/mock.html` を手で編集して調整した場合は、**差分（diff）または変更点の箇条書き**を入力として受け取る（状況で使い分けOK）
- その調整内容を根拠に、**HTMLだけでなくSSOT（`design-tokens.json` / `components.json` / `design_context.json`）も同時に更新**する
- SSOTが古いままだと、後続（`/design-ui` / `/design-components` / `/design-assemble`）で不整合が出るため、**HTML単独修正で終わらせない**

---

## ゲート
- 主要ブレイクポイントで破綻しない（簡易でOK）
- 情報設計（見出し/導線/主要CTA）が説明できる
- SSOT（tokens/components/context）が矛盾なく、`/design-ui` が実行できる状態になっている

