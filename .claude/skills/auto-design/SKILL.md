---
user-invocable: true
description: "Figma または会話を起点に、デザインSSOT抽出 → 確認用HTML → 静的UI骨格 → コンポーネント分離 → 型付き結合 → レビュー収束 → task→sprint マージまでを1コマンドで完結する。デザイン実装の Inner Loop 親スキル。"
---

# [ループ] 自律デザイン実装 `/auto-design`

> Loop Engineering の Inner Loop 親スキル（デザイン専用）。既存デザインスキル（design-ssot / design-mock / design-html / design-ui / design-components / design-assemble）を**連鎖呼び出し**して、Figma や会話から再利用可能な UI コンポーネントまで自律で運ぶ。スキル本体は触らない（Harness 層不可侵）。
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
- `task/*` ブランチ上で動く前提。`sprint/*` 上で起動されたら task ブランチを自動作成（`/auto-task` と同じ）。`main` 直下は中止
- 技術スタック（UI フレームワーク）・ターゲット表示環境は `doc/input/rdd.md` に従う。**未定義・未記入なら推測せず短問で確認**し、回答を rdd.md に反映してから進む（⚠️ **書き込む文面を見せて合意を得てから書く**。会話での一言を、AIが作った文面のまま要件として定着させない）（rdd.md 自体が無い場合も同様）
- **`project-design-language` を読み込む**: 基本方針（誰のため/北極星/単一メタファー）と固有値レジストリを SSOT 抽出・生成の前提にする
  - **雛形のまま**（基本方針が `{...}` / TBD）なら、`judgment-harness` の発酵ループに従い、**基本方針だけを質問して人間と埋めてから**ステップ1（SSOT 準備）へ進む（固有値レジストリは TBD のままでよく、SSOT 確定に合わせて同期する）
- **`art-direction` を読み込む**: ステップ2（確認用HTML）・ステップ3（静的UI骨格）の描画前に**AD宣言**を出し、描画後は `design-critique` の批評ループ（レンダリング→文脈遮断批評→修正を must-fix 0 まで、最大3周）を通す。確定した宣言は `project-design-language` の固有値レジストリへ同期する
- 課金が発生しうる操作は事前確認（`/auto-task` と同じ方針）

---

## 実行手順

### 0. ループ状態ファイルの初期化

`history/loop-state.md` を以下で開始（既存なら追記）:

```markdown
## YYYY-MM-DD HH:MM /auto-design <入力の要約>
- branch: <現在ブランチ>
- status: in_progress
- steps:
  - [ ] ssot (design-ssot / design-mock / 既存読込)
  - [ ] preview-html (design-html)
  - [ ] ui-skeleton (design-ui)
  - [ ] components (design-components)
  - [ ] assemble (design-assemble)
  - [ ] local-checks (lint/typecheck/test)
  - [ ] basic-review (致命指摘0まで)
  - [ ] deep-review (全指摘0まで)
  - [ ] pr-create + label + auto-merge (task→sprint)
  - [ ] vibe-handoff (人間へ引き渡し)
- last_action: ループ開始
```

各ステップ完了時に `[x]` 更新と `last_action` 書き換え（ADR-012）。

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

---

### 3. 静的UI骨格（design-ui）

- `design-ui` の手順で、技術スタック準拠の静的UI骨格（見た目のみ）を生成

---

### 4. コンポーネント分離（design-components）

- `design-components` の手順で Layout / Component を抽出し、技術スタックの標準配置に分離
- **命名は役割が一目でわかる形に**（CLAUDE.md 準拠。汎用名の衝突を避ける）

---

### 5. 型付き結合（design-assemble）

- `design-assemble` の手順で variants → 型付き Props/属性にマッピングし、再利用可能な UI として結合

---

### 6. ローカル検証

```bash
npm run lint
npm run typecheck
npm test   # コンポーネントテスト（描画・variants の分岐）を含む
```

- コンポーネントの**テストが存在しない場合は作成**する（variants ごとの描画確認を最低限）
- 失敗したら **bug-* スキル連鎖**（`/auto-task` ステップ3と同じ問題解決志向: 複数案→試行→効果検証→ロールバック）で自己修復し、直ったらここに復帰

---

### 7. basic-review / deep-review 反復

`/auto-task` のステップ4-5と同じ:
- `basic-review` を致命指摘0まで（最大5周）
- `deep-review` を全指摘0まで（最大3周）
- 超えたら中断してユーザー確認

---

### 8. PR 作成 → ラベル → 自律マージ（task → sprint）

`/auto-task` のステップ6-8と同じ:
- `gh pr create` で `task/* → sprint/*` の PR（本文に SSOT の出典 = Figma URL / 会話要約、確認用 HTML のパスを記載）
- `ai-merged-unreviewed` ラベル付与
- task → sprint のみ自律マージ。**sprint → main はしない**

---

### 9. Vibe Coding への引き渡し（人間の関所）

1. 確認用 HTML（`doc/input/design/html/`）と実装済みコンポーネントの確認方法（起動コマンド等）を提示
2. モードAの場合は **Figma 原本との対応関係**（どのフレーム → どのコンポーネント）を一覧で示す
3. 「触って『違う』を出してほしい」と明示して人間の Vibe 確認を待つ
4. Vibe フィードバックが出たら: タスク化 → SSOT / スキル側の修正 → このループを該当ステップから再実行（design TDD の発酵ループ。`dev-practices.md` 参照）
5. `history/loop-state.md` を `status: completed` に更新

---

## 課金前停止ポイント

`/auto-task` と同じ。加えて:
- Figma の有料 API / プラン変更を要する操作は事前確認

---

## 中断・再開

`/auto-task` と同じ仕組み。`history/loop-state.md` の `last_action` から再開判定。SSOT が生成済みならモードCとして再起動すれば続きから走る。

---

## やってはいけない

- Figma MCP 未接続のままモードAを推測で進める
- 技術スタック未定義のまま UI 骨格を推測で生成する
- SSOT を経由せず Figma から直接コードを書く（SSOT が唯一の起点。トレーサビリティを壊さない）
- Vibe Coding の関所を省略して「完成」と報告する
- sprint → main の自律マージ
- `history/loop-state.md` の更新を怠る

---

## `/auto-build` との関係

- `/auto-build` の Sprint ループ内で、**デザイン系の Issue**（画面・UI コンポーネント実装）は `/auto-task` の代わりにこのスキルを連鎖してよい
- 単独でデザインだけ回したいときの入口がこのスキル

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {SSOT抽出の精度、レビュー反復回数、Figma原本との対応の網羅度を踏まえて記載}
