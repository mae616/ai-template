---
name: auto-task
user-invocable: true
description: "task の自律実装ループ。task-run → テスト → bug 検知時 bug-* 連鎖 → basic-review → deep-review → PR → ai-merged-unreviewed ラベル → task→sprint 自律マージ までを1コマンドで完結。Inner Loop の親スキル。"
---

# [ループ] 自律タスク実装 `/auto-task`

> Loop Engineering の Inner Loop 親スキル。既存スキル（task-run / bug-* / basic-review / deep-review）を**連鎖呼び出し**して 1 task を自律で完了まで運ぶ。スキル本体は触らない（Harness 層不可侵）。
>
> **開始前に `.claude/skills/auto-loop-core/SKILL.md` を読み込み、共通手順はそれに従う**（読み込めなければ開始しない。ループ状態・ブランチ・ローカル検証・bug-* 連鎖・レビュー反復・マージの関所・課金前停止・中断再開）。ここには task 固有の手順だけを書く。
>
> 設計根拠: `meta/adr-lite.md` の **ADR-008 / ADR-009 / ADR-010**

## 入力: $ARGUMENTS
- Issue番号（例: `#123` または `123`）
- 省略時: 実行可能な Issue を `task-run` 側で選択

---

## 🎯 目的
- task の **実装〜マージまで自律で走らせる**
- 失敗・bug 検知時は **bug-* スキル連鎖** で自己修復
- レビュー指摘は **収束まで反復**
- 中断時は **`history/loop-state.md`** に記録、session-end が拾う

---

## 前提（必ず確認）

- ブランチの前提は `auto-loop-core` の「2. ブランチの前提」に従う（Issue タイトルから `task/YYYY-MM-機能名-詳細` を生成）
- **`doc/input/rdd.md` を読み込む**: 技術スタック・制約・非機能要件を実装の前提にする。実装判断に必要な項目が**未記入なら推測で埋めず短問で確認**し、回答を rdd.md に反映してから進む（⚠️ **書き込む文面を見せて合意を得てから書く**。会話での一言を、AIが作った文面のまま要件として定着させない）
- **UI・画面・コンポーネントを触る Issue の場合**は `project-design-language` を参照し、トーン・固有値（色/タイポ/モーション/文言）の判断根拠にする
  - **雛形のまま**（基本方針が `{...}` / TBD）なら、見た目や文言を**その場の勘で決めずに停止**し、基本方針を人間と埋めるか・TBD 明記の仮値（SSOT 参照）で進めるかを確認する
  - ただし **後行モードが選択済み**（`doc/input/rdd.md` に「デザイン適用タイミング: 後行」の記録がある。auto-build 連鎖中はその文脈でも可）の場合は、その選択を「TBD 明記の仮値で進める」合意とみなし、**停止せず**後行時実装規約（`dev-practices.md`: SSOT参照の仮値・セマンティック構造）で進めてよい

---

## 実行手順

### 0. ループ状態の初期化

`auto-loop-core` の「1. ループ状態の記録」で、`steps` を次のとおりにして開始する:

```markdown
  - [ ] task-run
  - [ ] local-checks (lint/typecheck/test)
  - [ ] basic-review (Must Fix 0まで)
  - [ ] deep-review (Critical・Warning 0まで)
  - [ ] pr-create
  - [ ] label-attach (ai-merged-unreviewed)
  - [ ] auto-merge (task→sprint)
  - [ ] sprint-check (Sprint 完了検知)
```

### 1. 実装（task-run スキル連鎖）

- `task-run` の手順に従って `$ARGUMENTS` のIssueを実装
- 完了したら **コミット**（task-run 側で適切に分割）

### 2. ローカル検証 → bug-* 連鎖

`auto-loop-core` の「3. ローカル検証」を実行する。失敗した、または実装途中で挙動異常を見つけた場合は「4. bug-* 連鎖」で自己修復し、直ったらこのループに復帰してマージまで続ける。

### 3. レビュー反復

`auto-loop-core` の「5. レビュー反復」に従う。

### 4. PR → ラベル → 自律マージ

`auto-loop-core` の「6. PR → ラベル → 自律マージ」に従う。task 固有の PR 本文:

- 主な変更点（コミット履歴から抽出）
- bug-* 連鎖を発動していた場合は経緯を簡潔に
- base は task ブランチを切った sprint ブランチ

### 5. Sprint 完了検知 → sprint→main PR の準備（マージはしない）

マージ後、対象 Sprint（実装した Issue の Milestone から特定）に open な task Issue が残っていないか確認する:

```bash
gh issue list --milestone "sprint-N" --state open --label task
```

**全タスク完了なら**、sprint → main の PR を**作成だけ**して人間へ引き渡す:

```bash
gh pr create --base main --head sprint/YYYY-MM-機能名 \
  --title "Sprint N: {Sprint目的}" \
  --body "..."  # Sprint内の全task PR一覧・テスト結果サマリ・ai-merged-unreviewed の残数を記載
```

- **Web のプロジェクトでは、PR 本文に「Web の公開範囲の未決: n件（項目名）」を必ず書く**（0件でも書く。数え方は `web-discoverability` の「照合する」の未決の一覧。照合を回していなければ、rdd の「Web の公開範囲」の行で未記入の項目を数える）。どの経路で PR を作っても同じ（auto-build・auto-design・人間が手で作る場合も、この項目を書く）。PR を作ったあとに未決が変わったら（F5 の磨き等）、本文の件数も直す

- **マージ判断は人間**（通常フローの最終関所）。AI は PR 作成と判断材料の提示まで
- `/auto-build` 経由の場合はエビデンスレポート（HTML）へのパスも本文に記載する
- 確認が済んだら（PR 作成の有無にかかわらず）`status: completed` に更新する

---

## やってはいけない

`auto-loop-core` の共通項目に加えて:

- `main` 上での起動（sprint/* 上なら task ブランチを切ってから始める）

---

## 次の一手
- **次に効くこと**: {次の工程・次のセッションが速く確実になる、具体的な一手を1つ}
- **引き継ぎの自信度**: (1-10) — この出力だけで次に再開できるか
- ⚠️ この欄に失敗の一覧を書かない（書くのは「次にどうするか」）。ただし次の判断が変わる事実（未検証・未書き出しのもの）は引き継ぎとして書く。PR 本文やレポートが求める試行の記録は、そちらに書く
