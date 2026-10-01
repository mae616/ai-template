# スキル見直し（2026-10）— 決定ログ

> 状態: **進行中**（群ごとに人間と決めて進める）。決めたことは各群の節に、未決は「決めていない」と明記する。
> 完了したら判断の背景を `meta/adr-lite.md` へ ADR として移し、このファイルは消してよい。

## 全体の進め方（決定）

1. **C. 中身・ラインナップ**を群ごとに人間と見る（自律ループ → デザイン → 判断軸 → 運用・メタ）
2. そのあと **A. 形式**（`name` 追加・description の「何を＋いつ」化）と **B. 構成**（長いスキルを `references/` へ分割）を一括でかける
3. 最後に、他エージェント（Codex / Cursor / Antigravity）から読める形で配る（`.agents/skills` リンク＋ `AGENTS.md` 生成）

照合基準: Agent Skills 仕様（agentskills.io/specification）と Claude Code 公式（code.claude.com/docs/en/skills）。

## 群をまたいで決めたこと

| 項目 | 決定 |
|---|---|
| 末尾の「自己評価（成功自信度 1-10）」 | **残す** |
| Claude Code 専用機能（組み込みTask・サブエージェント等）を前提にした手順 | **代替手順を1行添える**（例: サブエージェントが無ければ別の新しいセッションでレビュー） |

## 群1: 自律ループ系（13本＋新設1 `auto-loop-core`）— 完了

| 決定 | 内容 |
|---|---|
| ラインナップ | 維持（親 / 手順部品 / レビューで役割が分かれており重複なし） |
| 共通手順 | 新設の内部スキル `auto-loop-core` に集約。auto-task / auto-bug / auto-design / auto-build は固有手順だけを持つ |
| 理由 | 「`/auto-task` と同じ」＋要約の書き方で、auto-bug・auto-design のマージ段から**危険変更・main ベースでの停止条件が抜けていた**。共通手順は1か所に書き、要約・再掲しない |
| 代替手順 | task-list / task-detail / task-run（組み込みTask）、basic-review / deep-review（サブエージェント）、auto-build（両方）に1行ずつ追加 |

### 後続の候補（未着手）
- README の「自律ループ」節に `auto-loop-core`（内部スキル）の存在を1行書くか — **決めていない**
- task-run と bug-fix の「作業ブランチ作成」節がほぼ同文（違いはブランチ名だけ）。共通化するか — **決めていない**
- マージせずに止まった PR（危険変更・main ベース）にも `ai-merged-unreviewed` が付く。止まったときは付けない／別ラベル（例: `needs-human-merge`）にするか — **決めていない**（deep-review S3）
- README の自律ループ表「人間の関所」欄が、auto-design の危険変更停止や main ベース停止を反映していない — **決めていない**（deep-review S5。フロー見直しの論点1と一緒に決める）

### レビューで直したこと（deep-review: Critical 0 / Warning 7）
- 親スキル4本の冒頭に、`auto-loop-core` の読み込みを**パス付きで必須化**（読めなければ開始しない）
- status の種類を core に一覧で一本化（`blocked_by_main_base` / `blocked_by_user_confirm` / `blocked_by_sprint` を追加）。session-end の判定も `blocked_by_*` 全般を拾う形に
- 収束条件をレビュー側の用語に揃えた（basic: Must Fix 0 / deep: Critical・Warning 0）
- bug 連鎖の上限は「ループ全体の通算3周」と明記。ブランチは呼び出し元が定める形に
- 抜けていた運用（レビュー後のラベル外し・TDD の原則・ロールバック禁止など）を core に戻した

## 割り込み: フローの見直し（2026-10-01〜）
群2以降の前に、開発全体の流れ（工程のつながり）と人間の関所の流れを見直す。現状図と論点候補5件はレポート `doc/generated/reports/2026-10-01-flow-review.html`。**どの論点を直すかは決めていない。**

## 群2: デザイン系 — 未着手
## 群3: 判断軸（専門家）系 — 未着手
## 群4: 運用・メタ系 — 未着手
