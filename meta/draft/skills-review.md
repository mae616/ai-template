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

## 判断盤の決定（2026-10-01・人間）

出典: 判断盤 `meta/reports/2026-10-01-flow-intake-dashboard.html` でコピーされた判断。未決の項目で「取り込む」を選んだものは、**にゃんこのおすすめに沿う**意味（人間の補足）。

| 区分 | 決定 |
|---|---|
| フロー F0〜F5 | 採用。各工程を「作る → 批評する」の組にする |
| F4 | 1画面ずつではなく、**レスポンシブ・部品化まで一気に作り、終わったら人間が触る**。素材は Figma → design-ssot の SSOT（Figma が無ければスクリーンショット） |
| F6 動き・XState | 作らない。**決めていない**と明記してつなぐ場所だけ空ける |
| 取り込み | T4・T5・T7a・T7b・T8〜T13・T16〜T23・T21b・E1〜E4 を取り込む |
| O1 自己評価 | 「次の一手」＋「引き継ぎの自信度」に変える（群1の「残す」を上書き） |
| O2 | proto-loop・proto-medium・experience-plan を F1〜F3 に吸収して削除 |
| O3 | session-start を /setup に吸収して削除 |
| O5 | タスクボード（GitHub Projects / Orca / Linear）の既定は置かない。未設定なら /setup で聞く |
| O6 | Artifact が使えるかは /setup で聞く。使えなければローカル HTML＋判断のコピー |
| T6・O4・O7 | **決めていない**（あとで決める） |
| 台帳 | how-we-work 側の送り状は「状態」の行だけ書き換えてよい。他のファイルは触らない・コミットしない |

進め方: P1 土台のルール → P2 デザインの仕組み → P3 フロー → P4 配布 → P5 台帳。段ごとにコミットとレビュー。

### 追加の決定（2026-10-02・人間）: Web の公開設定をフローに入れる
- Web のプロジェクトでは、**OGP と SEO（Google 公式ガイドラインに沿う）を必ず設定する**
- **検索に出すか／ロボットを避けるか／AI の学習・検索に使わせるか**を人間に聞き、その答えで自動設定する
- 置き場（案）: 新規スキル `web-discoverability`（名前は**決めていない**）。F0 /setup で聞く → F4 で自動設定 → 数えるレビューで照合
- 書くときは公式一次情報で裏を取る（Google Search Central / ogp.me / 各社クローラーの公式ドキュメント）。P3 で実装
- 確認済みの一次情報（2026-10-02 取得。書く前に再確認する）:
  - Google SEO スターターガイド（最終更新 2025-12-10）: ページごとに固有の title・meta description、意味のある URL、canonical、構造化データ、画像の alt。サイトマップと robots.txt は任意。meta keywords は使われない — https://developers.google.com/search/docs/fundamentals/seo-starter-guide
  - noindex は meta か X-Robots-Tag。**robots.txt で塞いだページの noindex はクローラーに読まれない**（検索に出ることがある） — https://developers.google.com/search/docs/crawling-indexing/block-indexing
  - Google-Extended: Gemini の学習・グラウンディングの制御用トークン。**検索への掲載と順位には影響しない** — https://developers.google.com/search/docs/crawling-indexing/google-common-crawlers
  - OpenAI: GPTBot（学習）／OAI-SearchBot（ChatGPT の検索に出す）／ChatGPT-User（利用者の操作。robots.txt が効かない場合あり） — https://developers.openai.com/api/docs/bots
  - Anthropic: ClaudeBot（学習）／Claude-SearchBot（検索品質）／Claude-User（利用者の質問時）。サブドメインごとに robots.txt が要る — https://support.claude.com/en/articles/8896518
  - OGP 必須4つ: og:title / og:type / og:image / og:url。推奨: og:description / og:site_name / og:locale / og:image:alt / og:image:width・height — https://ogp.me/
  - → 聞く項目は「学習に使わせるか」と「AI 検索に出すか」を**分ける**（各社でボットが分かれている）

### P3-b で決めたこと（2026-10-02）
- 人間の決定: 設定集（`doc/draft/design/setting-book/`）は**残し**、design-language-options の下書きの置き場を兼ねる（判断盤の結果・採用と不採用の理由・事例・プロンプト集）。昇格先は project-design-language ではなく、デザインドックと値のファイル（F2）
- 人間の決定: ai-template のタスクボードは **Linear**（`meta/rdd.ai-template.md` の運用環境に記入）。このセッションでは Linear MCP が未認証で読めない
- 人間の決定: 1ラウンドに並べる案は「比較軸を1行で言える2〜3案」。dev-practices.md の「1案ごと／比較軸が明確なときだけ2案」を F1 に合わせて書き換えた
- 段1: `design-language-options` を新設し、proto-loop の連作（問い必須・1案1エージェントの文脈遮断・統合プロト・auto-build への引き継ぎ）と proto-medium（`references/medium.md`）を吸収して削除。F1 の「作る → 批評する」は、匿名テスト・導出線・比較軸の3問で入れた
- **P3-c へ送る**: proto-loop のステップ8（磨きラウンド: experience-plan → auto-task）は持ち込んでいない。F5（人間が触って磨く）で受け持つ。それまでは、auto-build のあとの「もう少し」を polish タスクとして起票し auto-task で回す（着手前チェックは task-run の手順4）
- **後続の候補**: プロトの置き場 `proto/*` ブランチが `.claude/rules/git.md` のブランチ構造に無い（旧 proto-loop から引き継いだ）。git.md に足すか `samples/proto-N/` に一本化するか — **決めていない**

### P3-a で決めたこと（2026-10-02）
- `/setup` を4段（前提 → 引き継ぎ → 環境 → 今日のゴールと GO）にし、session-start を削除。環境の答えは rdd の事実ブロック「運用環境」に書く（ai-template 自身では `meta/rdd.ai-template.md`。人間の決定）
- ai-template 自身の記録を `meta/` に集約（人間の指示）: 決定ログ → `meta/draft/`、レポート → `meta/reports/`、投函箱 → `meta/from-projects/`。`doc/` はアプリ用の空の雛形だけにし、`doc/index.md` の構成を今の雛形に合わせた
- 自己評価の欄を19本で「次の一手」に置き換え（proto-loop は P3-b で吸収・削除するので触らない）
- 新スキル名（人間が決定）: `design-language-options`（F1）／`web-discoverability`（Web の公開設定）

### P2 で決めたこと（2026-10-02）
- 値の正は既存の `design-tokens.json` 等。出典の `tokens.json` は作らない（値のファイルを2つにしない）
- 確定度は `meta.decision`、未決は `undecided`（`status` は assets の取得結果と衝突するので使わない）
- 新規: design-doc / design-audit（＋references/figma-measure.md）/ design-consistency、雛形 design-tokens.json・docs/README.md・screen-map.md
- **P3 へ送る**: 描く工程（design-mock / design-ui / auto-design）から design-consistency・design-doc・design-audit を呼ぶ接続
- **P3 へ送る**: proto-loop を吸収・削除するとき、設定集（setting-book）の扱いを決める。dev-practices の「デザイン/表現の発酵ループ」の節も proto-loop を前提にしている
- 人間の決定: AI が `doc/input/design/` に書くときも合意を取る（判断盤の選択はまとめて書いてよい。自律ループ中は doc/draft/ に候補）

### P1 で出た、後の段へ送るもの
- **P2**: 既存の値のファイル（`doc/input/design/copy.json`・`design_context.json`）に、確定か暫定かの区別と `undecided` の節が無い。スキーマの `status`（素材の取得結果 ok / failed）とキー名をぶつけない形で、雛形ごと直す
- **後続の候補**: 配布の保護（rdd・送り状・デザインの値とドック・レポート・git が無視するファイル）を、一時ディレクトリで新規・force・sync を流して判定する `test-apply-template.sh` を置く — **決めていない**
- ~~P3: doc-writing §8 の暫定表記~~ → P3-a で `/setup` に一本化して解消
- **後続の候補**: doc-writing §4（300行超は主題で割れないか疑う）に当たるもの — `meta/adr-lite.md`（1194行。§2 で積んでよい置き場）、`doc/input/design/ssot_schema.md`（423行）、`project-init/SKILL.md`（350行）、`README.md`（341行）。**割るかは決めていない**
- **後続の候補**: `meta/rdd.ai-template.md` の「現状スナップショット（2026-06-11時点）」の節が、doc-writing §2 の名指しの外で日付つきの内容を持っている — **決めていない**

## 割り込み: フローの見直し（2026-10-01〜）
群2以降の前に、開発全体の流れ（工程のつながり）と人間の関所の流れを見直す。現状図と論点候補5件はレポート `meta/reports/2026-10-01-flow-review.html`。**どの論点を直すかは決めていない。**

## 使っていないスキルの削除（2026-10-01・人間が選択）

根拠: 全プロジェクトのセッションログ（2026-08-18〜10-01、24プロジェクト）で、人間の `/コマンド` 呼び出し・AI のスキル呼び出しがともに0回のもの。

| スキル | 判断 | 理由・影響 |
|---|---|---|
| repo-tour / image-prep | **削除** | 参照は README と、2026-10-01 のフロー図レポート（スナップショットなので更新しない）だけ |
| pair | **削除** | project-init の壁打ちは手順を自前で持っていたので、見出しの参照2行だけ直した。pair から呼ばれていた判断軸（biz-researcher 等）は残す |
| docs-reverse | **残す** | 作る設計書（`doc/generated/reverse/modules/`）を task-run・basic-review・deep-review が前提にしている |
| keyboard-shortcuts / biz-researcher / proposition-reviewer / persona-designer | 残す | 人間が残すと判断 |
| ui-designer / usability-psychologist | 残す | design-fundamentals と重なる。群3（判断軸系）の見直しで再判断 |
| session-start | **削除**（P3-a） | /setup に吸収 |
| proto-loop / proto-medium | **吸収して削除**（P3-b 段1） | design-language-options へ。媒体の判断は `references/medium.md` |
| experience-plan | **吸収して削除**（P3-b 段2 予定） | task-run へ |
| pr-respond | **決めていない** | O4 |

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
