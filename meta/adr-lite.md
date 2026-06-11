# ADR-lite: ai-template 設計決定ログ

ai-template 自身の skills / rules / CLAUDE.md を変更したときの「なぜそうしたか」を記録する。
配布物（`.claude/` や `CLAUDE.md`）は圧縮した成果だけを持つため、判断の経緯はここに残す。

> 配置理由: `meta/` は `apply_template.sh` の配布対象外。テンプレ適用先には流れない。
> 生の壁打ちは `history/log.md`、圧縮した仕様は `meta/rdd.ai-template.md`、個別決定の経緯はここ。

形式（`rules/code-quality.md` の ADR-lite テンプレに準拠）:
**Context** 前提と問題 / **Decision** 決めたこと / **Consequences** 影響 / **Alternatives** 不採用案と理由

---

## ADR-001: インタラクション設計を rules に明文化（基本スタンス＋確認フロー）

- **日付**: 2026-06-05
- **対象**: `.claude/rules/dev-practices.md`
- **出典**: `history/log.md` L261-278（基本スタンス`[x]` / 確認フロー`[ ]`）

### Context
- AIの出力をスルーして blind merge する事故が起きていた（log L272）
- 自律モードが強くなり、合意なしにAIが着手してしまうのを避けたい（Human in the Loop 派）
- 音声入力主体のため、指示に誤字・言い換えが混ざる前提で意図を汲む必要がある
- これらは方針として確定済みだったが、skills/rules に落ちていなかった

### Decision
- `dev-practices.md` 冒頭に **基本スタンス** と **確認フロー** の2セクションを追加
- 確認フローは「事前確認（概念図→GO）→ 作業実行（Human on the Loop）→ 事後確認」の3段
- 事後確認に **人間の Vibe Coding フィードバックを必須化**: 区切りで使い勝手・体験を人間が触って確認 → タスク化 → レビューループで修正 → 再 Vibe 確認、を「いい感じになるまで」回す
- 自律度（Human in the Loop / on the Loop）の使い分け表を明記。デフォルトは in the Loop
- **進め方はプロトタイプ駆動（アジャイル）**を明記: 仕様駆動で先に全部を問わない（着手時は人間も答えを持たない）。動くものを先に出し Vibe で磨く
- **ワークフローは別ファイルに切り出さず rules 内に置く**: 確認フローが実質ワークフロー。別ファイル化（log L96-102）は rules 肥大化時の将来案。今切り出すのはオーバースペック

### Consequences
- (+) 全プロジェクトの AI が同じ協調モデルで動く。blind merge を関所で防げる
- (+) 言語化しにくい体験・意図を反映する工程が仕組みとして残る（核心動機の実装）
- (−) 事前確認・事後確認の往復が増え、速度は落ちる（ただし「速さより意図」が方針なので許容）

### Alternatives
- session-start スキルだけに書く案 → スキルは状況依存で読まれないことがある。rules は自動適用されるため確実性が高い → rules を採用
- CLAUDE.md に書く案 → CLAUDE.md は普遍ルール。運用フローは rules の領分なので分離

---

## ADR-002: 存在設計思想とファイル命名方針を CLAUDE.md へ

- **日付**: 2026-06-05
- **対象**: `CLAUDE.md`（目標・基本原則）
- **出典**: `history/log.md` L42-48 / L134-148（存在設計`[x]`）, L314-319（命名`[x]`）

### Context
- ai-template の核心動機は「速さ」ではなく「意図・存在設計・体験設計が宿ったアプリを作ること」
- この思想が CLAUDE.md（普遍ルールのSSOT）に未反映だった
- ファイル命名方針（名前で役割がわかる）も確定済みだが未明文化

### Decision
- **目標**に存在設計・体験設計の観点を2行追加（速さより意図 / 思考の流れが成果物に読み取れる）
- **基本原則**にAI時代のWeb表現探求・ログとデザインを思考の発酵場所とする観点・命名方針を追加
- 思想は**簡潔に**入れる（CLAUDE.md は技術判断のSSOTなので明瞭性優先。熱量の塊にはしない）
- **アプリ固有の意図（なぜこのアプリか）は CLAUDE.md に入れない**。各プロジェクトの `doc/input/rdd.md` 側に書く。CLAUDE.md には普遍スタンスのみ

### Consequences
- (+) 全プロジェクトの AI が「意図が宿る成果物」を前提に動く
- (+) 普遍（CLAUDE.md）とアプリ固有（rdd.md）の線引きが明確
- (−) 思想を簡潔化したため、熱量・背景は CLAUDE.md だけでは伝わりきらない（→ `meta/rdd.ai-template.md` が補完）

### Alternatives
- 思想を熱量そのまま長文で入れる案 → CLAUDE.md が肥大化し技術ルールが埋もれる → 簡潔版を採用、詳細は meta/ に委譲
- グローバル `~/.claude/CLAUDE.md` も同時更新する案 → グローバルは削除予定のため本体のみ更新

---

## ADR-003: 危険変更チェックリストを code-quality.md（ルール）へ

- **日付**: 2026-06-05
- **対象**: `.claude/rules/code-quality.md`
- **出典**: `history/log.md` L229-253（`[ ]`）, `meta/rdd.ai-template.md` L160-168

### Context
- 一人開発では認証・決済・削除など高リスク変更の見落としが事故に直結する
- 置き場所が「security-expert スキル or code-quality.md」で未確定だった

### Decision
- **`code-quality.md`（ルール）に追加**。常時自動適用で全変更に効かせる
- セキュリティ項目の詳細判断は `security-expert` スキルに委譲し、本リストは「変更時の関所」と役割分担を明記

### Consequences
- (+) DBマイグレーション・削除・通知など、security-expert の発火条件から漏れる運用リスクも取りこぼさない
- (+) 「コンテキスト依存ルール→仕組みで強制」の思想に沿う（常時適用＝取りこぼし減）
- (−) 本来の強制（hook/CI）ではなくテキストルールなので、AIが読み飛ばす余地は残る（CI/CD整備で将来補強）

### Alternatives
- security-expert スキルに入れる案 → スキルはセキュリティ文脈検知時のみ発火。運用リスク項目が漏れる → 不採用
- hook/CI で強制する案 → 最も確実だが今回スコープ外（CI/CD は後フェーズ）。将来補強として保留

---

## ADR-004: 開発日誌（journal.md）の運用開始と session スキル連携

- **日付**: 2026-06-05
- **対象**: `history/journal.md`（新規）, `session-start`/`session-end` スキル
- **出典**: `history/log.md` L341-353（`[ ]`）

### Context
- `session-context.md` はセッションごとに**上書き**される＝過去の経緯が消える
- 一人開発はコンテキストスイッチが多く「昨日何やったか」の想起コストが高い
- 積み上がる引き継ぎログが欲しい

### Decision
- `history/journal.md` を新規作成。`## YYYY-MM-DD` を上に積む引き継ぎ日誌
- `session-start` に「0. 前回からの引き継ぎ確認」（journal 最新エントリを読む）を追加
- `session-end` に「5.5 開発日誌へ追記」（上書きせず先頭に積む）を追加
- 書く=やったこと/引き継ぎ/判断メモ、書かない=反省・感情ログ（コスト高）
- 配置は `history/`（gitignore済み）→ クライアント情報も安全に書ける／公開リポジトリにも載らない

### Consequences
- (+) セッション冒頭で前回コンテキストが復元でき、想起コストが下がる
- (+) session-context.md（上書き・再開用）と journal.md（積み上げ・履歴）の役割が分離
- (−) journal.md は配布されない（history/ は apply_template 対象外）。各プロジェクトで初回は空から始まる（session-start がスキップ対応）

### Alternatives
- `history/YYYY-MM-DD.md` と日付ごとにファイル分割する案 → ファイルが増えて一覧性が落ちる → 単一ファイルに積む方式を採用
- session-context.md に履歴も兼ねさせる案 → 上書き運用と衝突。役割を分けるため別ファイルにした

---

## ADR-005: 個人環境とOSS公開ハーネスの分離

- **日付**: 2026-06-05
- **対象**: `~/.claude/settings.json`（グローバル）, `meta/personal-env/`, `.gitignore`

### Context
- ai-template は**フィードバックOSS**として公開している → 公開対象は「プロンプトハーネスとして再利用できるもの」に限るべき
- グローバル設定を一旦全削除したが、プラグイン/statusLine/音声入力/音などは**完全に個人・アプリ全体の設定**で、ハーネスの一部ではない
- Claude Code の設定は階層マージされ、グローバルとプロジェクトの hooks は両方発火する

### Decision
- **設定を3層に分離**:
  - 個人・アプリ全体（statusLine / plugins / voice / 音フック / 音源）→ `~/.claude/`（グローバル。公開しない）
  - 開発ワークフロー（permissions / 開発系 hooks / skills / rules / CLAUDE.md）→ ai-template の配布物（公開する）
  - 個人環境の記録・バックアップ → `meta/personal-env/`（gitignore＝ローカルのみ）
- `meta/personal-env/` はリポジトリ追跡から外し、ローカル保持に切り替え
- 公開する開発ドキュメント（`meta/rdd.ai-template.md` 等）からは**個人的文脈（契約・料金・属性）をスクラブ**し汎用表現にする

### Consequences
- (+) 公開リポジトリが「再利用可能なプロンプトハーネス」として純化される
- (+) 個人設定はグローバルで一元管理でき、プロジェクト hooks と両立する
- (−) `meta/personal-env/README.md` は過去コミットの履歴に残る（中身は非機密のため履歴書き換えはしない）

### Alternatives
- 個人設定もプロジェクトに置く案 → プラグイン等はアプリ全体設定でプロジェクト固有ではない。グローバルが適切 → 不採用
- 履歴を force push で書き換えて完全削除する案 → 非機密かつ破壊リスクが高い → 非推奨で見送り

---

## ADR-006: 送り状モデルの仕組み化と mae616-web 7項目の取り込み

- **日付**: 2026-06-11
- **対象**: `.claude/skills/{template-feedback,judgment-harness,project-design-language,image-prep}/`（新規）, `.claude/rules/dev-practices.md`, `CLAUDE.md`, `.claude/skills/{ui-designer,animation-principles}/SKILL.md`, `scripts/apply_template.sh`, `doc/output/to-template.md`（雛形）
- **出典**: mae616-web `doc/output/to-template.md`（送り状7項目・全て未取込だったもの）

### Context
- プロジェクトで得た汎用学びを ai-template へ還流する仕組みがなく、手作業・口伝だった
- mae616-web 側で「送り状モデル」（outbox／プロジェクトは template を直接編集しない＝競合回避／取り込みは template 側で直列処理）を設計済み。7項目が未取込で溜まっていた

### Decision
- **送り状モデルを仕組み化**: `template-feedback` skill（取り込み手順・/template-feedback で起動）＋ 送り状雛形 `doc/output/to-template.md` を配布物へ（`apply_template.sh` の INCLUDES に `doc/output/` を追加）＋ dev-practices「可視性の確保」に送り状習慣を1行
- **7項目を取り込み**。送り状の反映先候補から変えた点と理由:
  - 項目5（命名衝突）: `.card`→`.namecard` 等の固有例は載せず汎用表現のみ
  - 項目6（静止の焦点アンカー）: usability-psychologist ではなく **animation-principles のみ**に1行（モーション設計時に発火する場所が適切。二重記載回避）
  - 項目7（画像加工）: dev-practices へのツールメモは追加せず **`image-prep` skill に集約**（rules 肥大化回避）
  - 項目1: `judgment-harness` は user-invocable: true（立ち上げ時に明示起動できる）。穴埋め雛形 `project-design-language` は false
- **取り込み中のユーザーフィードバックをルール化**（このセッションの教訓）:
  - 「テンプレに書くのは**判断軸・優先順位・困ったとき何を疑うか・固有の手順/思想のみ**。AIが既に持つ一般知識・特定プロジェクトの具体例は書かない」→ `template-feedback` の反映工程に関所として明記
  - 「**思考の見える化（モデル非依存）**」→ CLAUDE.md 役割＋ dev-practices 基本スタンスへ追加。背景: モデルによっては判断過程を見せず結果だけ出し、Human in the Loop（判断基準は人間が握る）が機能しなくなるため、行動レベルで明文化した

### Consequences
- (+) 複数プロジェクト並行でも template が競合しない還流ループが回る（学びが揮発しない）
- (+) 判断軸ハーネス（レイヤー構造＋発酵ループ）で新規プロジェクトの立ち上げ方が型化される
- (−) 送り状の記入・取り込みの往復の手間が増える（「速さより意図」の方針で許容）

### Alternatives
- 各プロジェクトが ai-template を直接編集する案 → 並行開発で競合し判断も分散する → 不採用（送り状で直列化）
- 取り込みを hook/CI で自動化する案 → 「汎用化できるか」の判断は人間との対話が必要 → 手動の直列処理を採用
