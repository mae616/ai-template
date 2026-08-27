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

- このスキルは **`task/*` ブランチ上で動く前提**。`main` での起動は中止
- **`sprint/*` 上で起動された場合**は、対象 Issue 用の `task/*` ブランチを自動作成してから開始する（命名は `.claude/rules/git.md` 準拠）:

```bash
# 最新の sprint/* を取り込んでから task ブランチを切る
git pull
git checkout -b task/YYYY-MM-機能名-詳細   # Issue タイトルから生成
```
- **`doc/input/rdd.md` を読み込む**: 技術スタック・制約・非機能要件を実装の前提にする。実装判断に必要な項目が**未記入なら推測で埋めず短問で確認**し、回答を rdd.md に反映してから進む（⚠️ **書き込む文面を見せて合意を得てから書く**。会話での一言を、AIが作った文面のまま要件として定着させない）
- **UI・画面・コンポーネントを触る Issue の場合**は `project-design-language` を参照し、トーン・固有値（色/タイポ/モーション/文言）の判断根拠にする
  - **雛形のまま**（基本方針が `{...}` / TBD）なら、見た目や文言を**その場の勘で決めずに停止**し、基本方針を人間と埋めるか・TBD 明記の仮値（SSOT 参照）で進めるかを確認する
  - ただし **後行モードが選択済み**（`doc/input/rdd.md` に「デザイン適用タイミング: 後行」の記録がある。auto-build 連鎖中はその文脈でも可）の場合は、その選択を「TBD 明記の仮値で進める」合意とみなし、**停止せず**後行時実装規約（`dev-practices.md`: SSOT参照の仮値・セマンティック構造）で進めてよい
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

### 2. ローカル検証（lint / typecheck / テストピラミッド全層）

順に実行:

```bash
# プロジェクトの package.json / pyproject.toml 等を確認して適切なコマンドを選ぶ
npm run lint     # or eslint . / ruff check . など
npm run typecheck # or tsc --noEmit / mypy . など
npm test         # or pytest など（単体テスト）
npm run test:integration  # 結合テスト（存在する場合）
npm run test:e2e          # E2Eテスト（存在する場合）
```

- テストは **単体 → 結合 → E2E のピラミッド全層**を対象にする。テストの書き方・粒度は `testing` スキルに従う
- 変更箇所に対応するテストが**存在しない層があれば作成**してから検証する（t_wada流TDDの原則に沿い、本来は実装前に書く）

**判定**:
- すべて成功 → ステップ3へ
- 失敗 → **bug-* スキル連鎖発動**（次セクション）

---

### 3. bug 検知時のフォールバック（bug-* スキル連鎖）

ローカル検証で失敗を検知した、または実装途中で挙動異常を見つけた場合、**問題解決志向**（`/auto-bug` と同じ流儀）で自己修復する:

1. **bug-investigate** スキルで原因調査（Issue 起票はスキップ可、ローカルメモで進める）
2. **bug-propose** で修正案を**複数列挙**（恒久対応のみ。暫定対応は恒久案に置換）
3. **bug-fix** で修正案の**上から順に**実施し、各修正後にローカル検証で**効果を確認**:
   - **効果なし**: 修正前へ**ロールバック**して次案へ（無関係な修正を積み上げない）
   - **効果あり**: 確定してステップ4へ
4. ステップ2のローカル検証を**再実行**し、通ったら**元のタスクのループに復帰**してゴール（マージ）まで続行
5. 全案を試しても直らない場合は再調査から（最大3周）反復。**4周目に入る場合は中断してユーザー確認**:
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

**重要**: マージ対象は **task → sprint のみ**。sprint → main へは絶対に自律マージしない。**PR のベースが `main` の場合**（sprint/* が存在しないプロジェクト等）も自律マージせず、PR 作成とラベル付与までで停止して人間へ引き渡す。

**マージ前の停止条件（危険変更チェック）**: 変更が `.claude/rules/code-quality.md` の危険変更チェックリスト（認証・認可 / 決済 / 個人情報 / DBマイグレーション / 権限設定 / 外部API連携 / 削除処理 / 通知・メール送信）のいずれかに該当する場合、**自律マージせずここで停止**する:
- PR 作成とラベル付与までは実施し、`history/loop-state.md` に `status: blocked_by_danger_check` と該当項目を記録
- 「危険変更に該当するため人間のマージ判断が必要」とユーザーへ報告して終了

**該当しない場合のみ**自律マージする:

```bash
gh pr merge <PR-NUMBER> --squash --delete-branch
```

マージ完了後:
- `history/loop-state.md` の `status: completed` に更新
- ユーザーへ「`gh pr list --label ai-merged-unreviewed` で人間レビュー待ちPR一覧」を案内
- レビュー済みなら `gh pr edit <PR> --remove-label ai-merged-unreviewed` で外す運用

---

### 9. Sprint 完了検知 → sprint→main PR の準備（マージはしない）

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

- **マージ判断は人間**（通常フローの最終関所。危険変更該当時はステップ8でも人間判断が入る）。AI は PR 作成と判断材料の提示まで
- `/auto-build` 経由の場合はエビデンスレポート（HTML）へのパスも本文に記載する

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
