---
user-invocable: true
description: "task の自律実装ループ。task-run → テスト → bug 検知時 bug-* 連鎖 → basic-review → deep-review → PR → ai-merged-unreviewed ラベル → task→sprint 自律マージ までを1コマンドで完結。Inner Loop の親スキル。"
---

# [ループ] 自律タスク実装 `/auto-task`

> Loop Engineering の Inner Loop 親スキル。既存スキル（task-run / bug-* / basic-review / deep-review）を**連鎖呼び出し**して 1 task を自律で完了まで運ぶ。スキル本体は触らない（Harness 層不可侵）。
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

- このスキルは **`task/*` ブランチ上で動く前提**。`sprint/*` 直下や `main` での起動は中止
- ローカル lint / typecheck / test が**通る状態をゴール**にする（通らないまま PR は出さない）
- 課金が発生しうる操作（新規パッケージインストール、リモートデプロイ、外部 API 課金）は**事前にユーザーへ確認**して止まる
- usage 切れは Claude が自動停止に任せる（明示検知不要）

---

## 実行手順

### 0. ループ状態ファイルの初期化

`history/loop-state.md` を以下で開始（既存なら追記）:

```markdown
## YYYY-MM-DD HH:MM /auto-task #<issue-number>
- branch: <現在ブランチ>
- status: in_progress
- steps:
  - [ ] task-run
  - [ ] local-checks (lint/typecheck/test)
  - [ ] basic-review (致命指摘0まで)
  - [ ] deep-review (全指摘0まで)
  - [ ] pr-create
  - [ ] label-attach (ai-merged-unreviewed)
  - [ ] auto-merge (task→sprint)
- last_action: ループ開始
```

**各ステップ完了時に該当行を `[x]` に更新し、`last_action` を書き換える**。これが ADR-012 の中断時復帰の鍵。

---

### 1. 実装（task-run スキル連鎖）

- `task-run` の手順に従って `$ARGUMENTS` のIssueを実装
- 完了したら **コミット**（task-run 側で適切に分割）

> `task-run` の中身は触らない。ここではスキルを呼び出すだけ。

---

### 2. ローカル検証（lint / typecheck / test）

順に実行:

```bash
# プロジェクトの package.json / pyproject.toml 等を確認して適切なコマンドを選ぶ
npm run lint     # or eslint . / ruff check . など
npm run typecheck # or tsc --noEmit / mypy . など
npm test         # or pytest など
```

**判定**:
- すべて成功 → ステップ3へ
- 失敗 → **bug-* スキル連鎖発動**（次セクション）

---

### 3. bug 検知時のフォールバック（bug-* スキル連鎖）

ローカル検証で失敗を検知した、または実装途中で挙動異常を見つけた場合:

1. **bug-investigate** スキルで原因調査（Issue 起票はスキップ可、ローカルメモで進める）
2. **bug-propose** で修正案を列挙
3. **bug-fix** で恒久対応を実施
4. ステップ2のローカル検証を**再実行**
5. 通るまで（最大3周）反復。**4周目に入る場合は中断してユーザー確認**:
   - `history/loop-state.md` に `status: blocked_by_bug` を記録
   - 「3周試みたが修正できない。原因仮説と試行内容を提示するので方針を確認したい」とユーザーへ報告して終了

> bug-* スキル本体は触らない。ここでは連鎖呼び出しのみ。

---

### 4. basic-review 反復（致命指摘0まで）

1. `basic-review` 実行
2. **致命指摘**（typo・命名・フォーマット等の表面的ミスのうち、修正必須のもの）がある:
   - 指摘を反映 → コミット → 1. に戻る
3. 致命指摘0 → 次へ
4. **最大反復回数**: 5 周。超えたら中断してユーザー確認

---

### 5. deep-review 反復（全指摘0まで）

1. `deep-review` 実行
2. 全指摘を反映 → コミット → 1 に戻る
3. 全指摘0 → 次へ
4. **最大反復回数**: 3 周。超えたら中断してユーザー確認

---

### 6. PR 作成

- `gh pr create` で `task/* → sprint/*` の PR を作成
- 本文には:
  - Closes #<issue-number>
  - 主な変更点（コミット履歴から抽出）
  - bug-* 連鎖を発動していた場合は経緯を簡潔に
  - ローカル検証結果（lint/typecheck/test の成功）
- target ブランチは現在 task ブランチが切られた sprint ブランチ（`.claude/rules/git.md` 参照）

---

### 7. ラベル付与 `ai-merged-unreviewed`

```bash
# ラベルが存在しない場合は初回作成
gh label create ai-merged-unreviewed \
  --description "AI が自律マージした PR。人間目視レビュー前" \
  --color "FF9F40" 2>/dev/null || true

# PR にラベル付与
gh pr edit <PR-NUMBER> --add-label ai-merged-unreviewed
```

---

### 8. 自律マージ（task → sprint）

**重要**: マージ対象は **task → sprint のみ**。sprint → main へは絶対に自律マージしない。

```bash
gh pr merge <PR-NUMBER> --squash --delete-branch
```

マージ完了後:
- `history/loop-state.md` の `status: completed` に更新
- ユーザーへ「`gh pr list --label ai-merged-unreviewed` で人間レビュー待ちPR一覧」を案内
- レビュー済みなら `gh pr edit <PR> --remove-label ai-merged-unreviewed` で外す運用

---

## 課金前停止ポイント（実行中の確認プロンプト）

以下に該当する操作の**直前にユーザーへ確認**して止まる:

- 新規パッケージインストール（特に従量課金 SaaS を絡める場合）
- リモートデプロイ
- 任意の従量課金 SaaS への新規呼び出し（Claude API 以外の外部 API）
- GitHub Actions の有料ランナー起動

**確認なしで OK**: gh CLI / git / lint / typecheck / test / ローカルツール全般

---

## 中断・再開

- API エラーや usage 切れで停止した場合、`history/loop-state.md` の最終 `last_action` から再開する
- 次回 session-start で journal を読めば中断箇所が分かる（ADR-012）
- 手動で再開する場合は `/auto-task <同じissue>` を再起動。状態ファイルから続きを判定する

---

## やってはいけない

- `task/*` 以外のブランチで起動（特に main、sprint/* 直下）
- sprint → main の自律マージ
- bug-* 連鎖を 3 周以上回しても直らない時に押し切ってマージ
- 課金発生ポイントの確認をスキップ
- ローカル検証が落ちたまま PR 作成
- `history/loop-state.md` の更新を怠る

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {ループの収束過程で詰まりがなかったか、bug-* 連鎖の発動回数、レビュー反復回数を踏まえて記載}
