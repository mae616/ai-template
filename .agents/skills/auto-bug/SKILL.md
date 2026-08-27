---
user-invocable: true
description: "bug の自律修正ループ。bug-investigate → bug-propose → bug-fix → テスト → basic-review → deep-review → PR → ai-merged-unreviewed ラベル → task→sprint 自律マージ までを1コマンドで完結。Inner Loop の親スキル。"
---

# [ループ] 自律バグ修正 `/auto-bug`

> Loop Engineering の Inner Loop 親スキル（bug 専用）。既存スキル（bug-investigate / bug-propose / bug-fix / basic-review / deep-review）を**連鎖呼び出し**して 1 bug を自律で完了まで運ぶ。
>
> 設計根拠: `meta/adr-lite.md` の **ADR-008 / ADR-009 / ADR-010**
>
> 関連: `/auto-task` は task 実行中に bug 検知すると bug-* 連鎖を内部発動する（こちらは bug 単独処理の入口）

## 入力: $ARGUMENTS
- Issue番号（例: `#123` または `123`）
- 省略時: ラベル `bug` がついた Issue から選択

---

## 🎯 目的
- bug の **調査〜修正〜マージまで自律で走らせる**
- 修正案が複数ある場合は **提案 → 効果検証 → 採用** の流れで進める
- 効果なしならロールバックして次案へ
- 中断時は **`history/loop-state.md`** に記録

---

## 前提（必ず確認）

- 対象 Issue に `bug` ラベルが付いているか、または bug-new で起票済みであること
- `feature_fix/*` ブランチで動く（`.Codex/rules/git.md` 参照）
- 課金が発生しうる操作は事前にユーザー確認（`/auto-task` と同じ方針）

---

## 実行手順

### 0. ループ状態ファイルの初期化

`history/loop-state.md` を以下で開始:

```markdown
## YYYY-MM-DD HH:MM /auto-bug #<issue-number>
- branch: <現在ブランチ>
- status: in_progress
- steps:
  - [ ] bug-investigate
  - [ ] bug-propose
  - [ ] bug-fix (恒久対応・効果検証)
  - [ ] local-checks (lint/typecheck/test)
  - [ ] basic-review
  - [ ] deep-review
  - [ ] pr-create
  - [ ] label-attach
  - [ ] auto-merge
- last_action: ループ開始
```

各ステップ完了時に `[x]` 更新と `last_action` 書き換え。

---

### 1. 調査（bug-investigate）

- `bug-investigate` の手順に従って原因を絞り込む
- 仮説と再現手順を Issue コメントに追記

---

### 2. 修正案列挙（bug-propose）

- `bug-propose` の手順で修正策を列挙し、Issue コメントに追記
- 恒久対応のみ（暫定対応はスキップまたは恒久案に置換）

---

### 3. 修正実行＋効果検証（bug-fix）

- `bug-fix` の手順で**修正案の上から順に**実施
- 各修正後に**ローカル lint / typecheck / test** で効果検証
- **効果なし**: 修正前へロールバック → 次案へ
- **効果あり**: 確定してステップ4へ
- 全案を試して直らない場合:
  - `history/loop-state.md` に `status: blocked_by_bug` を記録
  - 試行内容と新たな仮説をユーザーへ報告して終了

---

### 4. ローカル検証（最終確認）

```bash
npm run lint
npm run typecheck
npm test
```

すべて通ることを確認。失敗したらステップ3に戻る（最大3周）。

---

### 5. basic-review 反復

`/auto-task` のステップ4と同じ手順（致命指摘0まで、最大5周）。

---

### 6. deep-review 反復

`/auto-task` のステップ5と同じ手順（全指摘0まで、最大3周）。

---

### 7. PR 作成

- `gh pr create` で **適切なブランチ → sprint/*** の PR を作成
  - スプリント統合後に見つかった bug → `feature_fix/* → sprint/*`
  - task 実装中に派生した bug → `task/* → sprint/*`
  - 判断基準は `.Codex/rules/git.md` 参照
- 本文には:
  - Closes #<issue-number>
  - 採用した修正案（複数試した場合は経緯）
  - 試した順序と効果の有無
  - ローカル検証結果
- target ブランチは適切な sprint ブランチ

---

### 8. ラベル付与・自律マージ

`/auto-task` のステップ7-8と同じ:
- `ai-merged-unreviewed` ラベルを付与
- `feature_fix/* → sprint/*` を `gh pr merge --squash --delete-branch`
- **sprint → main は絶対に自律マージしない**

---

## 課金前停止ポイント

`/auto-task` と同じ（新規パッケージ・リモートデプロイ・有料外部 API・有料 CI）。

---

## 中断・再開

`/auto-task` と同じ仕組み。`history/loop-state.md` の `last_action` から再開判定。

---

## やってはいけない

- `bug` Issue として起票されていない問題に対していきなり `/auto-bug` を起動
  - その場合は先に `bug-new` で起票
- 修正案を試さずにいきなり「直らない」と諦める
- 効果検証なしで複数案を同時にコミット
- ロールバックせず無関係な修正を積み上げる
- sprint → main の自律マージ

---

## `/auto-task` との関係

- `/auto-task` は **task 実装中に bug を検知**したら bug-* スキル**連鎖を内部発動**する（コマンドとしての `/auto-bug` は呼ばない）
- `/auto-bug` は **bug が分かっている状態で人間が単独起動**する入口
- どちらも同じ既存スキル群（bug-investigate / bug-propose / bug-fix / review 系）を呼ぶ → 動作はほぼ同じ

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {何案目で直ったか、ロールバックの回数、レビュー反復回数を踏まえて記載}
