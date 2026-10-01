---
user-invocable: true
description: "Figma または会話を起点に、デザインSSOT抽出 → 確認用HTML → 静的UI骨格 → コンポーネント分離 → 型付き結合 → レビュー収束 → task→sprint マージまでを1コマンドで完結する。デザイン実装の Inner Loop 親スキル。"
---

# [ループ] 自律デザイン実装 `/auto-design`

> Loop Engineering の Inner Loop 親スキル（デザイン専用）。既存デザインスキル（design-ssot / design-mock / design-html / design-ui / design-components / design-assemble）を**連鎖呼び出し**して、Figma や会話から再利用可能な UI コンポーネントまで自律で運ぶ。スキル本体は触らない（Harness 層不可侵）。
>
> **開始前に `.claude/skills/auto-loop-core/SKILL.md` を読み込み、共通手順はそれに従う**（読み込めなければ開始しない。ループ状態・ブランチ・ローカル検証・bug-* 連鎖・レビュー反復・マージの関所・課金前停止・中断再開）。ここにはデザイン固有の手順だけを書く。
>
> 設計根拠: `meta/adr-lite.md` の **ADR-008 / ADR-014 / ADR-015**
>
> 最後の関所は **人間の Vibe Coding**（触って「違う」を出す確認）。デザインは仕組みで拾えない感覚判断が本質のため、コード品質の収束までを AI が担い、体験の判断は人間に返す。

## 入力: $ARGUMENTS

3通りの入口を受け付ける:

| モード | 入力例 | 動き |
|---|---|---|
| **A: Figma** | `/auto-design <FigmaのURL/refs>` | `design-ssot` で SSOT（tokens/components/context/assets）を抽出 |
| **B: 会話** | `/auto-design "ダッシュボード画面。落ち着いたトーンで"` | `design-mock` で SSOT + HTML叩き台を生成 |
| **C: 既存SSOT** | `/auto-design doc/input/design/` | 既存のSSOT一式を読み込み、SSOT準備をスキップしてステップ2から開始 |

---

## 🎯 目的

- デザインの取り込み〜**再利用可能な型付きコンポーネント**までを1コマンドで運ぶ
- 途中の品質（レビュー収束・検証）は AI が担保し、**体験の判断（Vibe）だけを人間に返す**
- 中断時は `history/loop-state.md` に記録して再開可能にする

---

## 前提（必ず確認）

- **モードA**: Figma MCP が接続済みであること（未接続なら中止してユーザーに案内）
- ブランチの前提は `auto-loop-core` の「2. ブランチの前提」に従う
- 技術スタック（UI フレームワーク）・ターゲット表示環境は `doc/input/rdd.md` に従う。**未定義・未記入なら推測せず短問で確認**し、回答を rdd.md に反映してから進む（⚠️ **書き込む文面を見せて合意を得てから書く**。会話での一言を、AIが作った文面のまま要件として定着させない）（rdd.md 自体が無い場合も同様）
- **`project-design-language` を読み込む**: 基本方針（誰のため/北極星/単一メタファー）と固有値レジストリを SSOT 抽出・生成の前提にする
  - **雛形のまま**（基本方針が `{...}` / TBD）なら、`judgment-harness` の発酵ループに従い、**基本方針だけを質問して人間と埋めてから**ステップ1（SSOT 準備）へ進む（固有値レジストリは TBD のままでよい。値は SSOT（値のファイル）が正で、確定したらレジストリには決定の一言と置き場だけを書く）
- **`design-consistency` の「フローの中の位置」を読む**: ステップ1の前に、第1部のどのレベルまで決まっているかを確かめる。足りないときの扱いは同節に従う（`/auto-design` は単独で起動しても自律ループなので、ここは「自律ループの中」に当たる。仮の値で描き進め、手順9でまとめて聞く。`auto-build` から呼ばれたときは、auto-build のエビデンスレポートの「判断待ち」にも載る）
- **`art-direction` を読み込む**: ステップ2（確認用HTML）・ステップ3（静的UI骨格）の描画前に**AD宣言**を出し、描画後は `design-critique` の批評ループ（レンダリング→文脈遮断批評→修正を must-fix 0 まで、最大3周）を通す（ステップ2・3の検品は下の「2.5」）。確定した宣言は `project-design-language` の固有値レジストリへ同期する
- 課金前停止は `auto-loop-core` の「7. 課金前停止」に加えて、Figma の有料 API / プラン変更を要する操作も事前確認する

---

## 実行手順

### 0. ループ状態の初期化

`auto-loop-core` の「1. ループ状態の記録」で、`steps` を次のとおりにして開始する:

```markdown
  - [ ] ssot (design-ssot / design-mock / 既存読込)
  - [ ] preview-html (design-html)
  - [ ] critique-audit (design-critique / design-audit)
  - [ ] ui-skeleton (design-ui)
  - [ ] critique-audit-skeleton (骨格に design-critique / design-audit)
  - [ ] components (design-components)
  - [ ] assemble (design-assemble)
  - [ ] local-checks (lint/typecheck/test)
  - [ ] basic-review (Must Fix 0まで)
  - [ ] deep-review (Critical・Warning 0まで)
  - [ ] pr-create + label + auto-merge (task→sprint)
  - [ ] vibe-handoff (人間へ引き渡し)
```

---

### 1. SSOT 準備（入口判定）

- **モードA**: `design-ssot` の手順で Figma から SSOT を抽出
- **モードB**: `design-mock` の手順で会話から SSOT + HTML叩き台を生成
- **モードC**: 既存の SSOT 一式を読み込んで妥当性を確認（下記ファイルが揃っているか）

> 以降のループの SSOT は `doc/input/design/` 配下の JSON 一式（`design_context.json` / `design-tokens.json` / `components.json` / `copy.json` / `assets/assets.json`）。スキーマは `doc/input/design/ssot_schema.md` に従う。

---

### 2. 確認用 HTML 生成（design-html）

- `design-html` の手順で SSOT から静的 HTML を生成し `doc/input/design/html/` に保存
- これが**人間の Vibe 確認とエビデンスの土台**になる（モードBで叩き台が既にある場合はスキップ可）

### 2.5. 数える検品（design-audit）

- 確認用 HTML（とステップ3のあとは骨格）を、`design-audit` で値のファイル・ドックと照合する。通過の条件は同スキルの「収束条件」
- 直さないもの（正に無い・人間に聞くもの）は、止まらずに `undecided` かタスクボードのカードにして進み、手順9でまとめて人間に聞く
- 直して再走査するのは最大3周（design-critique と同じ）。収束しなければ `auto-loop-core` の `blocked_by_review` で止まる

---

### 3. 静的UI骨格（design-ui）

- 着手前に、`task-run` の「体験の網羅」のチェックリストを宣言する（auto-design は task-run を通らないため、ここで当てる）
- `design-ui` の手順で、技術スタック準拠の静的UI骨格（見た目のみ）を生成

---

### 4. コンポーネント分離（design-components）

- `design-components` の手順で Layout / Component を抽出し、技術スタックの標準配置に分離
- **命名は役割が一目でわかる形に**（CLAUDE.md 準拠。汎用名の衝突を避ける）

---

### 5. 型付き結合（design-assemble）

- `design-assemble` の手順で variants → 型付き Props/属性にマッピングし、再利用可能な UI として結合

---

### 6. ローカル検証 → bug-* 連鎖

`auto-loop-core` の「3. ローカル検証」を実行する。デザイン固有の点:

- コンポーネントテスト（描画・variants の分岐）を含める。**テストが存在しない場合は作成**する（variants ごとの描画確認を最低限）
- 失敗したら「4. bug-* 連鎖」で自己修復し、直ったらここに復帰する

---

### 7. レビュー反復

`auto-loop-core` の「5. レビュー反復」に従う。

---

### 8. PR → ラベル → 自律マージ（task → sprint）

`auto-loop-core` の「6. PR → ラベル → 自律マージ」に従う。PR 本文には SSOT の出典（Figma URL / 会話要約）と確認用 HTML のパスを書く。

---

### 9. Vibe Coding への引き渡し（人間の関所）

1. 確認用 HTML（`doc/input/design/html/`）と実装済みコンポーネントの確認方法（起動コマンド等）を提示。仮の値で描いた項目と、design-audit で `undecided` に回したものを一覧にして、まとめて聞く
2. モードAの場合は **Figma 原本との対応関係**（どのフレーム → どのコンポーネント）を一覧で示す
3. 「触って『違う』を出してほしい」と明示して人間の Vibe 確認を待つ
4. Vibe フィードバックが出たら: タスク化 → SSOT / スキル側の修正（直した理由はデザインドックに書く。`design-doc`）→ このループを該当ステップから再実行（design TDD の発酵ループ。`dev-practices.md` 参照）
5. `history/loop-state.md` を `status: completed` に更新

---

## 中断・再開

`auto-loop-core` の「8. 中断・再開」に従う。SSOT が生成済みならモードCとして再起動すれば続きから走る。

---

## やってはいけない

`auto-loop-core` の共通項目に加えて:

- Figma MCP 未接続のままモードAを推測で進める
- 技術スタック未定義のまま UI 骨格を推測で生成する
- SSOT を経由せず Figma から直接コードを書く（SSOT が唯一の起点。トレーサビリティを壊さない）
- Vibe Coding の関所を省略して「完成」と報告する

---

## `/auto-build` との関係

- `/auto-build` の Sprint ループ内で、**デザイン系の Issue**（画面・UI コンポーネント実装）は `/auto-task` の代わりにこのスキルを連鎖してよい
- 単独でデザインだけ回したいときの入口がこのスキル

---

## 次の一手
- **次に効くこと**: {次の工程・次のセッションが速く確実になる、具体的な一手を1つ}
- **引き継ぎの自信度**: (1-10) — この出力だけで次に再開できるか
- ⚠️ この欄に失敗の一覧を書かない（書くのは「次にどうするか」）。ただし次の判断が変わる事実（未検証・未書き出しのもの）は引き継ぎとして書く。PR 本文やレポートが求める試行の記録は、そちらに書く
