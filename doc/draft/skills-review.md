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

## 使っていないスキルの削除（2026-10-01・人間が選択）

根拠: 全プロジェクトのセッションログ（2026-08-18〜10-01、24プロジェクト）で、人間の `/コマンド` 呼び出し・AI のスキル呼び出しがともに0回のもの。

| スキル | 判断 | 理由・影響 |
|---|---|---|
| repo-tour / image-prep | **削除** | 参照は README と、2026-10-01 のフロー図レポート（スナップショットなので更新しない）だけ |
| pair | **削除** | project-init の壁打ちは手順を自前で持っていたので、見出しの参照2行だけ直した。pair から呼ばれていた判断軸（biz-researcher 等）は残す |
| docs-reverse | **残す** | 作る設計書（`doc/generated/reverse/modules/`）を task-run・basic-review・deep-review が前提にしている |
| keyboard-shortcuts / biz-researcher / proposition-reviewer / persona-designer | 残す | 人間が残すと判断 |
| ui-designer / usability-psychologist | 残す | design-fundamentals と重なる。群3（判断軸系）の見直しで再判断 |
| proto-loop / proto-medium / experience-plan / session-start / pr-respond | **決めていない** | 新しいフローの形で要否が変わる。フローと一緒に決める（session-start は /setup へ吸収する案） |

## 群2: デザイン系 — 着手（2026-10-01）

| 決定 | 内容 |
|---|---|
| 新設 `design-fundamentals` | デザインの基本を「当てる問い」の形で持つ総覧。本体は索引＋4原則（近接・整列・反復・対比）＋自己点検。`references/` にゲシュタルト / 文字と階層 / 色とコントラスト / 余白とグリッド / 操作と使いやすさ / UXの法則 / UIの文言 の7本 |
| 由来 | how-we-work 送り状 項目8の新規スキル `layout-principles` を一般化して本体に取り込み、有名な本・公式の基本を references に足した（人間の要望「有名なデザインの本の基本を、呼び出せる形で」） |
| 接続 | design-drafter（描く前に読む・返す前に自己点検）/ design-mock・design-ui（読み込み）/ design-critique（Q11・Q12 に統合、Q14・Q15 を追加、「要実測」の扱いを追加）/ art-direction（一般則を委譲） |
| 文言 | 一般則は `references/ux-writing.md`。**プロダクト固有の声とトーンは `project-design-language` で決める**（デザイン言語と同じ扱い） |

### 後続の候補（未着手）
- 送り状 項目8の残り（`design-consistency`・project-design-language の索引・「宣言は照合の代わりにならない」）は、送り状21件の取り込みと一緒に扱う。**項目8の状態はまだ倒さない**（一部だけ取り込んだため）
- how-we-work の画面を題材に、批評ループ（design-critique の Q14・Q15）を回して効き目を確かめる — **人間の要望あり・未実施**
## 群3: 判断軸（専門家）系 — 未着手
## 群4: 運用・メタ系 — 未着手
