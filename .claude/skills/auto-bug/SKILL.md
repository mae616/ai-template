---
user-invocable: true
description: "bug の自律修正ループ。bug-investigate → bug-propose → bug-fix → テスト → basic-review → deep-review → PR → ai-merged-unreviewed ラベル → task→sprint 自律マージ までを1コマンドで完結。Inner Loop の親スキル。"
---

# [ループ] 自律バグ修正 `/auto-bug`

> Loop Engineering の Inner Loop 親スキル（bug 専用）。既存スキル（bug-investigate / bug-propose / bug-fix / basic-review / deep-review）を**連鎖呼び出し**して 1 bug を自律で完了まで運ぶ。
>
> **開始前に `.claude/skills/auto-loop-core/SKILL.md` を読み込み、共通手順はそれに従う**（読み込めなければ開始しない。ループ状態・ブランチ・ローカル検証・bug-* 連鎖・レビュー反復・マージの関所・課金前停止・中断再開）。ここには bug 固有の手順だけを書く。
>
> 設計根拠: `meta/adr-lite.md` の **ADR-008 / ADR-009 / ADR-010**

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
- `feature_fix/*` ブランチで動く（`.claude/rules/git.md` 参照）

---

## 実行手順

### 0. ループ状態の初期化

`auto-loop-core` の「1. ループ状態の記録」で、`steps` を次のとおりにして開始する:

```markdown
  - [ ] bug-investigate
  - [ ] bug-propose
  - [ ] bug-fix (恒久対応・効果検証)
  - [ ] local-checks (lint/typecheck/test)
  - [ ] basic-review
  - [ ] deep-review
  - [ ] pr-create
  - [ ] label-attach
  - [ ] auto-merge
```

### 1. 調査 → 修正案 → 修正と効果検証

`auto-loop-core` の「4. bug-* 連鎖」を、Issue を起点に実行する:

- 調査の仮説と再現手順は Issue コメントに追記する（`bug-investigate`）
- 修正案も Issue コメントに追記する（`bug-propose`）。暫定対応は採らず恒久案に置き換える

### 2. ローカル検証（最終確認）

`auto-loop-core` の「3. ローカル検証」ですべて通ることを確認する。失敗したら手順1に戻る（「4. bug-* 連鎖」の上限に従う）。

### 3. レビュー反復

`auto-loop-core` の「5. レビュー反復」に従う。

### 4. PR → ラベル → 自律マージ

`auto-loop-core` の「6. PR → ラベル → 自律マージ」に従う。bug 固有の点:

- ブランチ → base の対応（判断基準は `.claude/rules/git.md`）:
  - スプリント統合後に見つかった bug → `feature_fix/* → sprint/*`
  - task 実装中に派生した bug → `task/* → sprint/*`
- PR 本文には、採用した修正案（複数試した場合は経緯）と、試した順序・効果の有無を書く

---

## やってはいけない

`auto-loop-core` の共通項目に加えて:

- `bug` Issue として起票されていない問題に対していきなり `/auto-bug` を起動
  - その場合は先に `bug-new` で起票
- 修正案を試さずにいきなり「直らない」と諦める
- 効果検証なしで複数案を同時にコミット

---

## `/auto-task` との関係

- `/auto-task` は **task 実装中に bug を検知**したら bug-* スキル**連鎖を内部発動**する（コマンドとしての `/auto-bug` は呼ばない）
- `/auto-bug` は **bug が分かっている状態で人間が単独起動**する入口
- どちらも `auto-loop-core` の同じ bug-* 連鎖を使う → 動作はほぼ同じ

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {何案目で直ったか、ロールバックの回数、レビュー反復回数を踏まえて記載}
