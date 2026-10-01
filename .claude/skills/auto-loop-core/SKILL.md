---
name: auto-loop-core
user-invocable: false
description: "自律ループ（auto-task / auto-bug / auto-design / auto-build）が共通で従う手順。ループ状態の記録、ローカル検証と bug-* 連鎖、レビュー反復、PR→ラベル→task→sprint 自律マージの関所（危険変更・main ベースで停止）、課金前停止、中断・再開を定める。auto-* 系スキルの実行中に参照する。"
---

# [ループ] 自律ループ共通手順

> auto-* 系の親スキルが**共通で従う手順**。親スキルは開始時に必ずこのファイルを読み込む。各親スキルには固有の手順だけを書き、ここに書いた手順を要約・再掲しない（要約すると停止条件が抜け落ちるため）。
>
> 設計根拠: `meta/adr-lite.md` の **ADR-008 / ADR-009 / ADR-010 / ADR-012**

---

## 1. ループ状態の記録

`history/loop-state.md` に以下の形で開始する（既存なら追記）。`steps` は呼び出し元スキルが定める。

```markdown
## YYYY-MM-DD HH:MM /<スキル名> <対象（#issue / 入力の要約）>
- branch: <現在ブランチ>
- status: in_progress
- steps:
  - [ ] <呼び出し元が定める手順>
- last_action: ループ開始
```

- 各手順の完了時に `[x]` へ更新し、`last_action` を書き換える（中断時の復帰に使う）
- `status` は次のいずれか。`blocked_by_*` で止まるときは、理由と該当項目を併記して人間へ報告し、終了する。ただし `blocked_by_user_confirm` は確認待ちで、承認されたら `in_progress` に戻して続きから進める（却下されたらそのまま終了する）

| status | 意味 |
|---|---|
| `in_progress` | 実行中（この状態のまま止まっていたら中断） |
| `completed` | 呼び出し元の全手順が完了 |
| `blocked_by_bug` | bug-* 連鎖が上限を超えた |
| `blocked_by_review` | レビュー反復（basic-review / deep-review、デザインでは design-critique / design-audit）が上限を超えた。どのレビューかを理由に書く |
| `blocked_by_danger_check` | 危険変更に該当し、マージを人間に委ねた |
| `blocked_by_main_base` | main ベースになる（PR のベースが main、または進行中の sprint が無い）ため、マージやブランチの切り方を人間に委ねた |
| `blocked_by_user_confirm` | 課金前停止で確認待ち |
| `blocked_by_sprint` | Sprint 内で blocked が重なり、Sprint ループ全体を止めた（auto-build） |

## 2. ブランチの前提

- 動くブランチと切るブランチは呼び出し元が定める（task は `task/*`、bug は `feature_fix/*`）。命名は `.claude/rules/git.md` に従う
- `sprint/*` 上で起動された場合は、`git pull` してから呼び出し元が定めるブランチを切って開始する
- `main` 上での起動は**中止**する

## 3. ローカル検証

プロジェクトの定義ファイル（`package.json` / `pyproject.toml` 等）から適切なコマンドを選び、lint → typecheck → テストを順に実行する。

- テストは**単体 → 結合 → E2E のピラミッド全層**が対象（書き方は `testing` スキル）。結合・E2E はスクリプトが存在する場合に実行する
- 変更箇所に対応するテストが無い層があれば、作成してから検証する（TDD の原則では本来は実装前に書く）
- 失敗したら下の「4. bug-* 連鎖」へ。通らないまま PR を出さない

## 4. bug-* 連鎖（問題解決志向）

1. `bug-investigate` で原因を調査する（task 中の派生なら Issue 起票は省略し、ローカルメモで進めてよい）
2. `bug-propose` で**恒久対応の修正案を複数**列挙する
3. `bug-fix` で**上から順に**試し、1案ごとにローカル検証で効果を確かめる
   - 効果なし → 修正前へ**ロールバック**して次案へ（無関係な修正を積み上げない）
   - 効果あり → 確定してローカル検証を再実行し、元の手順に復帰する
4. 全案で直らなければ再調査から反復する。**上限はループ全体の通算で3周**（復帰後のローカル検証が再び落ちて戻った場合も1周に数える）。超えたら `status: blocked_by_bug` を記録し、仮説と試行内容を添えて報告して終了する

## 5. レビュー反復

各レビューの収束判定はレビュー側の定義に従う。

1. `basic-review` を **Must Fix 0件まで**反復する（指摘反映 → コミット → 再実行。**最大5周**）
2. `deep-review` を **Critical / Warning 0件まで**反復する（指摘反映 → コミット → 再実行。**最大3周**）。Suggestion は対応してよいが、収束判定には使わない
3. 上限を超えたら `status: blocked_by_review` を記録して止まる

## 6. PR → ラベル → 自律マージ（関所）

1. `gh pr create` で作業ブランチ → `sprint/*` の PR を作る。本文には、ローカル検証結果、Issue があれば `Closes #<issue>`、呼び出し元が定める固有項目を書く
2. ラベル `ai-merged-unreviewed` を付ける:

   ```bash
   gh label create ai-merged-unreviewed \
     --description "AI が自律マージした PR。人間目視レビュー前" \
     --color "FF9F40" 2>/dev/null || true
   gh pr edit <PR-NUMBER> --add-label ai-merged-unreviewed
   ```

3. **次のいずれかに当たる場合は自律マージしない**。どちらも status を記録し、「人間のマージ判断が必要」と理由を添えて報告して終了する:
   - PR のベースが `main`（sprint/* が無いプロジェクト等）→ `blocked_by_main_base`
   - 変更が `.claude/rules/code-quality.md` の**危険変更チェックリスト**（認証・認可 / 決済 / 個人情報 / DBマイグレーション / 権限設定 / 外部API連携 / 削除処理 / 通知・メール送信）に該当する → `blocked_by_danger_check`（該当項目も記録）
4. 当たらない場合のみ `gh pr merge <PR-NUMBER> --squash --delete-branch` で自律マージする
5. マージ後:
   - 呼び出し元にこのあとの手順が無ければ `status: completed` に更新する（ある場合は該当 step を `[x]` にして続ける）
   - `gh pr list --label ai-merged-unreviewed` で人間レビュー待ちの一覧を見られることを案内する
   - 人間がレビューを終えたら `gh pr edit <PR> --remove-label ai-merged-unreviewed` でラベルを外す運用であることも伝える

## 7. 課金前停止

次の操作の**直前に**、`status: blocked_by_user_confirm` を記録してユーザーへ確認し、止まる:

- 新規パッケージのインストール（特に従量課金 SaaS が絡む場合）
- リモートデプロイ
- 従量課金の外部 API への新規呼び出し
- GitHub Actions の有料ランナー起動

gh CLI / git / lint / typecheck / test などローカルで完結する操作は確認不要。usage 切れは自動停止に任せ、検知の仕組みは作らない（ADR-012）。

## 8. 中断・再開

- API エラーや usage 切れで止まった場合は、`history/loop-state.md` の最後の `last_action` から再開する（次回の `/setup` でも拾える）
- 手動で再開するときは、同じ引数で親スキルを起動し直す。親スキルは状態ファイルを読んで、完了済みの step を飛ばして続きから進める

## やってはいけない（全 auto-* 共通）

- **sprint → main の自律マージ**（人間の最終関所）
- 上限を超えた bug 連鎖・レビュー反復を押し切ってマージする
- 効果のなかった修正をロールバックせず、次の案を積み上げる
- ローカル検証が落ちたまま PR を作る
- 課金前停止の確認を飛ばす
- `history/loop-state.md` の更新を怠る
