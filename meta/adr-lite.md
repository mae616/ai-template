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

---

## ADR-007: モデル運用方針をモデル非依存へ転換

- **日付**: 2026-06-12
- **対象**: `meta/rdd.ai-template.md`「モデル運用方針」

### Context
- 旧方針は「Opusは自律着手する・対話が遅い → 基本Sonnet」とモデル名指しの使い分けだった
- 実際には CLAUDE.md / rules に「自律着手しない」等を明文化したことで、Opusでも問題が出なくなった（ユーザー実感）。一方で Fable 5 では「思考が見えない」という別のモデル固有問題が新たに発生 → モデル名指しの対策はモデルが変わるたびに陳腐化する

### Decision
- **モデル非依存を原則**にする: 特定モデル向けの個別対策は書かない。協調スタイル（自律着手しない・思考の見える化・Human in the Loop）は CLAUDE.md / rules / スキル側で担保する
- モデル固有の問題を見つけたら、モデル名で対処せず「ルール/スキルにどう書けば防げるか」へ汎用化して反映する

### Consequences
- (+) モデルを乗り換えても協調モデルが崩れず、各モデルの性能の恩恵だけを受けられる
- (+) モデルのアップデートのたびに方針を書き直す必要がない
- (−) 仕組み側の文言で防げないモデル固有問題が出た場合、原因の切り分けに一手間かかる

### Alternatives
- モデルごとの注意点リストを維持する案 → モデル更新のたびに陳腐化し、リスト自体が信頼できなくなる → 不採用

---

## ADR-008: ループエンジニアリングの全体ビジョン（5層モデル）

- **日付**: 2026-06-21
- **対象**: ai-template 全体方針（実装は ADR-009 以降で個別化）
- **出典**: `history/journal.md` 2026-06-21 エントリ（壁打ち全体）

### Context
- 2026年6月、Loop Engineering（Addy Osmani / Boris Cherny / Peter Steinberger 発）が AI コーディング界の新トレンドに浮上
- 進化系譜: Prompt（〜2024）→ Context（2025）→ Harness（2026初頭）→ **Loop（2026.6〜）**
- このリポは Context 層（CLAUDE.md/rdd.md 等）と Harness 層（44スキル+rules+hooks）は厚いが、**Loop 層が薄い**
- 6/15 に `self-driving-loop` スキルを「重い」と削除した経緯がある → 同じ轍を避ける必要
- ユーザー直観: 「1スラッシュコマンドでユースケース実行」型（=Inner Loop）に振りたい。Outer Loop（cron的）は最小限

### Decision
ループエンジニアリング取り込みを **5層モデル**で整理し、今回スコープを **L1部分+L2+L4+L5** に絞る:

| L | 役割 | 今回スコープ |
|---|---|---|
| L1 | 思考の場（要件・設計の HTML 化サイト） | ✅ 既存全 doc を HTML 化（要件・デザイン・ADR含む全コンテキスト閲覧） |
| L2 | 自律実装ループ（task/bug の親ループ） | ✅ `/auto-task` `/auto-bug` 新設（ADR-009） |
| L3 | 1ユースケース処理（人間フィードバック後の修正等） | ❌ 既存スキルで代替、今回は外す |
| L4 | 観測・記録（PR/思考プロセスの HTML 残し） | ✅ `reviewable-html-workbench` プラグイン統合（後半 ADR） |
| L5 | ガードレール（usage 切れ・課金前停止） | ✅ 自動停止 + 未完了記録（後半 ADR） |

**設計原則**:
- **Inner Loop 優先**: 1コマンドで完結する親ループを設計。Outer Loop（時間駆動 cron）は採用しない
- **既存スキルは触らない**: 親ループは既存スキル（task-run / bug-fix / basic-review / deep-review 等）を**連鎖呼び出し**するだけ。Harness 層と Loop 層を分離
- **モデル非依存（ADR-007 継承）**: 親ループは手続きで賢さを補う。特定モデル前提にしない

### Consequences
- (+) 既存 Harness 層（44スキル）を再利用できる。実装コスト軽め
- (+) Inner Loop なので「重くて使われない」失敗（6/15 self-driving-loop 削除の教訓）を避けられる
- (+) ループエンジニアリングのトレンドを取り込みつつ、このリポの「人間 on the Loop」思想と整合
- (−) Outer Loop（夜中走らせ）は今回入らない。後で必要なら追加
- (−) L3 を外したため、人間フィードバック後の修正は既存スキル（pr-respond / task-run 等）を手動で呼ぶ運用が続く

### Alternatives
- **全層一気に実装**: 数週間〜数ヶ月仕事。6/15 の失敗（重さで死蔵）を繰り返すリスク → 段階導入を採用
- **Outer Loop 採用**（`/loop 30m /auto-task` 等）: 派手だが運用が重い・トークン消費激しい・誤発火怖い。このリポの性格に合わない → Inner Loop に絞る
- **スキル復活（旧 self-driving-loop 再導入）**: 6/15 削除の教訓を尊重。スキルでなく**親コマンド**として実装 → スキル復活は不採用

---

## ADR-009: 自律実装ループ `/auto-task` `/auto-bug`（L2）

- **日付**: 2026-06-21
- **対象**: `.claude/commands/auto-task.md`（新規）, `.claude/commands/auto-bug.md`（新規）
- **出典**: ADR-008 全体ビジョン

### Context
- L2「自律実装ループ」の具体実装
- 既存スキル群が **Inner Loop の素材**として揃っている: `task-run` / `bug-investigate` / `bug-propose` / `bug-fix` / `basic-review` / `deep-review` / `pr-respond` 等
- 必要なのは**これらを連鎖する親コマンド**
- ユーザー要件: task 実行中に bug 検知したら自律的に bug 処理へフォールバック

### Decision
**2つの親コマンドを新設**:

**`/auto-task <issue#>`** — task 自律処理:
```
1. task-run（実装）
2. ローカル lint + typecheck
3. テスト実行
   └─ 失敗/不整合検知 → 内部で bug-* スキル連鎖発動
        ├─ bug-investigate
        ├─ bug-propose
        └─ bug-fix
4. basic-review 反復（致命指摘0まで）
5. deep-review 反復（全指摘0まで）
6. PR 作成（gh CLI）
7. ラベル付与 `ai-merged-unreviewed`（ADR-010）
8. task → sprint へ自律マージ（ADR-010）
```

**`/auto-bug <issue#>`** — bug 単独処理:
```
1. bug-investigate
2. bug-propose
3. bug-fix
4. テスト確認
5. /auto-task と同じ後半（review→PR→label→merge）
```

**設計のキモ**:
- `/auto-task` が `/auto-bug` を**コマンドとして呼ぶ**のではなく、内部で**bug-* スキルを連鎖呼び出し**する（同一セッション内での処理）
- `/auto-bug` は人間が単独でも呼べる独立コマンドとして両立
- どちらも既存スキルを**そのまま再利用**。スキル本体は触らない
- 親コマンドは Markdown プロンプトファイル（`.claude/commands/*.md`）として実装。Boris Cherny / Anthropic 公式と同じ流儀

### Consequences
- (+) 既存 44 スキルを壊さず、新規ファイル 2 本（`auto-task.md`, `auto-bug.md`）で L2 が完成
- (+) Inner Loop なので 1 起動で完結。usage 消費が予測しやすい
- (+) bug 検知時のフォールバックが組み込まれているため、テスト失敗で止まらず自走する
- (−) `/auto-task` の中身（Markdown プロンプト）の品質がループ全体の品質を決める → 初版から完璧は無理、運用しながら磨く
- (−) スキル連鎖の途中で詰まった場合、どこで止まったか追跡が必要（→ ADR-012 で session-end が未完了箇所を記録する）

### Alternatives
- **Stop Hook で再投入する Ralph Loop パターン**: Anthropic 公式の Ralph Wiggum と同じ流儀。完了文字列まで強制反復。L3 まで含むなら有力だが、L2 だけなら親コマンドの方が読みやすい → 採用見送り（将来必要なら追加）
- **Workflow スクリプト（多エージェント敵対的検証）**: Boris の `/batch` 的なパターン。トークン消費が重い。L2 の標準動作には過剰 → 採用見送り（深い review 等の限定用途で将来）
- **スキル本体を改造して連鎖呼び出しを内蔵**: スキルの責務が肥大化し再利用性が落ちる → 親コマンド側で連鎖する分離設計を採用

---

## ADR-010: マージ戦略（ラベル運用パターン、AI 自律マージ）

- **日付**: 2026-06-21
- **対象**: ADR-009 の親コマンド内動作（gh CLI のラベル運用）, `git.md` は無改訂

### Context
- ADR-009 で AI が自律マージする設計を採用 → どのブランチまで AI 自律で、どこから人間レビューか の線引きが必要
- 既存 `git.md`: `task/* → sprint/* → main` の3層。sprint→main は CI＋人間レビュー必須
- ユーザー懸念: 人間目視前に main へ入る事故を防ぎたい
- 検討した選択肢:
  - A: 現状ブランチ構造 + ラベル運用
  - B: `task/* → ai-sprint/* → sprint/* → main` の4層化
  - C: スプリント PR は人間トリガーのみ

### Decision
**選択肢 A 採用**: 現状ブランチ構造維持 + ラベル運用

**ルール**:
- `task/*` → `sprint/*`: **AI 自律マージ可**。PR 作成時に `ai-merged-unreviewed` ラベルを付与
- `sprint/*` → `main`: **人間レビュー＆マージ必須**（git.md の既存ルールそのまま）
- ユーザーが PR を目視確認したら、ラベル `ai-merged-unreviewed` を手動で外す（or 将来 `/reviewed` コマンドで自動外し）
- 未レビュー PR の一覧は `gh pr list --label ai-merged-unreviewed` で取得可能

**git.md は無改訂**: ブランチ構造は変えない。AI 自律マージはあくまで `task/* → sprint/*` の範囲内で、既存ルールと整合する

### Consequences
- (+) `git.md` 既存ルールを破らずに AI 自律マージが組み込める
- (+) ラベルだけで「人間未確認」を可視化できる。GitHub 標準機能のみで完結
- (+) sprint→main は人間がレビューする原則が守られるため、本番影響を伴うマージは必ず人手を経る
- (+) sprint 単位で「AI が組み立てた中身」を人間が一括レビューできる（task ごとにレビュー強制よりも軽い）
- (−) `sprint/*` 内に「AI 統合済み・未レビュー」と「人間確認済み」が混在する状態が発生する（ラベルで区別）
- (−) ラベル付与・剥がしのオペレーションがユーザー側で必要（最初は手動、将来コマンド化）

### Alternatives
- **B: 4層化（`task/* → ai-sprint/* → sprint/* → main`）**: 物理的に AI/人間ラインが分離して安心感あり。ただし git.md 改訂が必要、ブランチ階層が深くなり promote 作業が増える。運用負荷が上回る → 不採用
- **C: スプリント PR は人間トリガー**: AI 自律マージの旨みが減る。task→sprint の大量マージ後に sprint→main の差分が膨らみレビュー負荷が逆に増える → 不採用
- **task→sprint も人間マージ**: AI 自律ループの価値を消す。L2 採用の動機と矛盾 → 不採用

---

## ADR-011: 全コンテキスト HTML サイト（L1 部分採用）

- **日付**: 2026-06-21
- **対象**: 新規スラッシュコマンド `/build-context-site`（仮）, 既存 `design-html` skill との関係整理
- **出典**: ADR-008、ユーザー要件「ここ見れば人間も全コンテキスト分かるよ」的なローカル HTML サイト

### Context
- L1（思考の場）のうち、**HTML 設計書サイト**だけを部分採用する
- ユーザー要件: 既存 design ドキュメントが Markdown 中心で、HTML 化されていない → **ローカルで閲覧できる HTML サイト**として全コンテキストを横断できる場が欲しい
- 既存資産:
  - `design-html` skill: Markdown/JSON から HTML を生成
  - `design-mock` / `design-ssot` / `design-ui` skill: デザイン段階の HTML 生成
  - `reviewable-html-workbench` プラグイン（ADR-013 で統合）: HTML レンダリング機能あり
- 「全コンテキスト」の範囲: `doc/input/*` + `doc/generated/*` + `meta/adr-lite.md` + 関連 `history/*`（gitignore 配下なのでローカルのみ）

### Decision
**全コンテキスト HTML サイトを生成する親コマンドを新設**:

**`/build-context-site`**（仮称）の動作:
1. 対象ドキュメントを収集:
   - `doc/input/*.md`（要件定義、デザイン SSOT 等）
   - `doc/generated/*`（マニュアル、設計書）
   - `meta/adr-lite.md`（設計決定ログ）
   - `history/journal.md` の最新N日分（ローカル閲覧用、配布物には含まない）
2. **MCP の drawio / mermaid で図を埋め込む**（要件・設計の構造可視化）
3. `reviewable-html-workbench` の `render` を使って HTML バンドル生成
4. ローカルプレビューサーバを起動 → ブラウザで `/index.html` を開く
5. ナビゲーションは「ファイル一覧 + 横断検索」で全文を渡り歩ける形

**生成物の置き場**: `doc/generated/context-site/`（配布対象外）

**既存スキルとの関係**:
- `design-html` / `design-mock` / `design-ui` / `design-ssot` は**デザイン領域の HTML 生成**を担当（既存責務維持）
- `/build-context-site` は**横断的にサイト化する親コマンド**として上位レイヤで動く。スキルは触らない

### Consequences
- (+) 人間が「このプロジェクトの全前提」をブラウザ1つで把握できる → 引き継ぎ・確認コスト激減
- (+) AI も同じサイトを参照対象にできる（Context 層の補強）
- (+) drawio/mermaid 図を埋め込むことで Markdown だけより構造理解が早い
- (+) `reviewable-html-workbench` のレンダリング基盤を再利用 → 実装軽量
- (−) サイト生成のたびに各ドキュメントの最新状態を再収集する必要（手動更新 or watch モードは後で検討）
- (−) `history/` は gitignore 配下のためチーム共有不可。ローカル閲覧専用と割り切る

### Alternatives
- **既存 `design-html` skill を拡張して全コンテキスト化**: スキル責務が「デザイン」から「全ドキュメント」に肥大化 → スキル分離原則違反。新規親コマンドを採用
- **静的サイトジェネレータ（Docusaurus 等）導入**: 学習コスト・依存追加が重い。既存 `reviewable-html-workbench` で足りる範囲 → 採用見送り
- **doc/input を直接 HTML で書く**: Markdown 編集の手軽さを失う。Markdown→HTML 変換を採用

---

## ADR-012: ガードレール（usage 自動停止 + 未完了記録）

- **日付**: 2026-06-21
- **対象**: `session-end` skill 拡張, 親コマンド（ADR-009）内の課金前確認プロンプト
- **出典**: ADR-008 L5、ユーザー要件「クレジット切れたら止まる」「できてないとこ判断して session-end に残す」

### Context
- 自律ループ（ADR-009）が暴走すると課金事故になる → ガードレールが必要
- ただしユーザー要件は**最小限**:
  - usage 切れの**自動検知＆復活再開は不要**（Claude が API エラーで勝手に止まるのに任せる）
  - 課金発生ポイント（外部 API 呼び出し等）は**事前に止める**
  - **未完了箇所を session-end に記録**して、次セッションで再開できるように
- L5 を「過剰に作り込まない」のが方針（重さで死蔵を避ける ADR-008 の精神を継承）

### Decision
**ガードレールを3点に絞る**:

1. **usage 切れは自動停止に任せる**
   - Anthropic API のレート/クレジット切れは Claude セッションが自然停止する → 明示的な検知ロジックは作らない
   - 親コマンド側で「停止検知」のための polling 等は不要

2. **課金発生ポイントは確認プロンプトで止める**
   - 親コマンド内（ADR-009 の `/auto-task` / `/auto-bug`）で以下の操作直前に **人間確認を挟む**:
     - 新規パッケージインストール（`npm install` 等で従量課金 SaaS が絡む場合）
     - リモートデプロイ（本番影響）
     - 外部 API 呼び出し（OpenAI/Anthropic 以外の従量課金サービス）
     - GitHub Actions の有料ランナー起動（今回は CI 保留のため発火想定なし）
   - ローカルツール（gh CLI / git / lint / typecheck / test）は課金ゼロなので**確認不要**

3. **未完了箇所を session-end が記録**
   - `session-end` skill を拡張: セッション終了時に「自律ループが途中で止まったか」を判定
   - 判定ロジック: `/auto-task` `/auto-bug` の進行状態（実装中／レビュー中／PR 作成中／マージ前 等）を**状態ファイル**（`history/loop-state.md`、gitignore）に逐次書く設計
   - `session-end` が状態ファイルを読んで「未完了の場合は journal に「中断・再開ポイント」を明示」する
   - 次セッションで `session-start` がこれを拾って続きから再開できる

**状態ファイル**: `history/loop-state.md`
- 親コマンド開始時に新規作成
- 各ステップ完了時に追記
- 完了時にクリアまたはアーカイブ

### Consequences
- (+) 過剰実装を避けつつ、最低限の安全網が機能する
- (+) usage 切れの「復活検知＆再開」を作らないことで実装コストが激減（ユーザー方針）
- (+) 未完了箇所が journal に残るため、次セッションでコンテキストロスなく再開できる
- (+) 課金前停止は親コマンドの prompt に書くだけで実現できる（hook 不要）
- (−) usage 切れの瞬間に状態ファイルが書き終わってない可能性（最終状態を毎ステップ flush することで緩和）
- (−) 「課金発生ポイント」の網羅性は親コマンド作成者の判断に依存（運用しながらリスト拡充）

### Alternatives
- **usage 監視を polling で実装**: API コール費用が増える＋運用が重い。ユーザー却下 → 不採用
- **すべての破壊的操作で確認プロンプト**: 確認の嵐になり自律ループの旨みが消える → 課金ポイントに絞る
- **状態ファイルを JSON にする**: 機械可読性は上がるが、人間が journal と並べて読む時 Markdown が楽 → Markdown 採用

---

## ADR-013: `reviewable-html-workbench` 統合（L4 観測・記録）

- **日付**: 2026-06-21
- **対象**: 新規依存（外部プラグイン）, `/auto-task` `/auto-bug` の出力フェーズ拡張
- **出典**: ADR-008 L4、ユーザー指定リポ `u-ichi/reviewable-html-workbench`

### Context
- L4「観測・記録」: AI の PR・思考プロセス・成果物を **HTML で残し、人間が後追いレビュー可能**にする
- `reviewable-html-workbench`（ユーザー自作の Claude Code プラグイン）が**まさにこの用途**: HTML バンドル生成 + ブラウザ上でインライン コメント + AI がコメントを読み取り更新
- 機能: skills（`visual-html-renderer`, `reviewable-design-doc`, `plan-preview`）+ CLI（`render`, `ingest-review`, `watch-comments` 等）
- インストール: `claude plugin marketplace add u-ichi/reviewable-html-workbench` → `claude plugin install reviewable-html-workbench`

### Decision
**`reviewable-html-workbench` を依存として組み込み、2用途で活用**:

**用途1: 設計段階のレビュー**（L1 と連動）
- `/build-context-site`（ADR-011）が生成する HTML を `reviewable-html-workbench` 経由で出力
- 人間がブラウザでコメント → AI が `ingest-review` で読み取り → 設計を更新

**用途2: 自律ループの成果残し**（L4 本体）
- `/auto-task` / `/auto-bug`（ADR-009）の最終ステップで、以下を HTML バンドル化:
  - **PR の中身**（diff、コミットメッセージ、関連 issue リンク）
  - **思考プロセスログ**（task-run / bug-investigate / レビューループの判断履歴）
  - **テスト結果・review 指摘の収束履歴**
- 出力先: `doc/generated/loop-reports/<timestamp>-<task-id>/`
- ローカルプレビューサーバで閲覧可能 → 人間が後から流し読み＆コメント可能
- コメントが付いたら、次の `/auto-task` 起動時に AI が拾って改善ループへフィードバック

**統合の最小範囲**:
- プラグインは**依存として install するだけ**。本体は触らない
- ai-template 側では `/auto-task` の最終ステップに「`reviewable-html-workbench` の `render` 呼び出し」を追加するだけで完了

### Consequences
- (+) AI の作業履歴が**ブラウザで人間レビュー可能な形**で残る → blind merge 防止の Vibe Coding ループ（dev-practices.md）と完全整合
- (+) `reviewable-html-workbench` がユーザー自作で**よく分かっている依存**（外部リスクが小さい）
- (+) コメント → AI 取り込みの双方向フィードバックが動く → self-improving メモリ的に効く
- (+) L1（設計段階）と L4（実装後）の両方で同じ仕組みを再利用できる
- (−) 外部プラグイン依存が1つ増える（更新の追従が必要）
- (−) `reviewable-html-workbench` 本体に問題があった場合、ai-template 側で完全には吸収できない（軽い結合に留めることで緩和）

### Alternatives
- **HTML 出力を自前実装**: 車輪の再発明。`reviewable-html-workbench` がインライン コメント機能を含んで揃っている → 自前不採用
- **GitHub PR ページのみで完結**: PR コメントだけだと思考プロセス・テスト履歴等を整理して残しにくい。HTML バンドルの方が情報密度が高い → PR + HTML の併用採用

---

## ADR-014: ループ運用向け権限の事前緩和（settings.json への直接反映）

### Context
- miku2026 で auto-task / auto-bug を回した際、`gh issue create/edit/comment/close/reopen` `gh pr create/review` `gh project item-add` `gh api *` `git push *` が `ask` に入っていて確認プロンプトで止まる事象が頻発
- 送り状（miku2026）からは `.claude/settings.local.json.example` テンプレ + rules（新規 `loop-engineering.md`）追記が候補として上がっていた
- ai-template は「ループ運用前提のテンプレート」（`auto-task` / `auto-bug` を親スキルとして既に同梱）

### Decision
- `settings.local.json.example` は新設せず、**配布される `.claude/settings.json` 本体の `allow` に直接移動**する
- 移動: `git push *` / `gh issue create|edit|comment|close|reopen *` / `gh pr create|review *` / `gh project item-add *` / `gh api *`
- 維持される `ask`（破壊的・統合系）: `gh pr merge` / `gh pr close` / `rm *` / `git branch -D` / `git reset` / `git clean` / `npm install` / `brew` / `docker`
- 専用 rules（`loop-engineering.md`）は作らない。判断軸は ADR と settings.json のコメントレスな構造で読み取れる

### Consequences
- (+) 配布された全プロジェクトでループ運用が摩擦なく回る（個人で `.local.json` を作らなくて済む）
- (+) `pr merge` / `branch -D` / `reset` / `clean` / `rm` 等の破壊的操作は引き続き `ask` で関所を維持
- (−) `git push *` を allow に上げているため、力のある操作が事前承認となる（破壊的なのは branch -D / reset / force 側に集約されているので影響限定）

### Alternatives
- **`settings.local.json.example` 配布**: 個人で copy する手間が増える / 配布物を増やしたくない → 不採用
- **新規 `loop-engineering.md` rules**: 常時読込される rules を肥大化させる。判断軸は settings.json + ADR で十分 → 不採用
- **Notion/Confluence 等の外部サービス**: クラウド依存が増える、課金リスク、ユーザー方針（ローカル閲覧優先）と矛盾 → 不採用

---

## ADR-014: 最上位親ループ `/auto-build`（プロンプト/成果物 → 完成＋エビデンス）

- **日付**: 2026-07-04
- **対象**: `.claude/skills/auto-build/SKILL.md`（新規）, `.claude/skills/auto-task/SKILL.md`（強化）, `.claude/skills/task-list/SKILL.md` `.claude/skills/task-detail/SKILL.md`（次のステップ配線）
- **出典**: 2026-07-04 セッションのユーザー要求（「プロンプト文だけで最後まで作ってくれるもの」「既存成果物からも作れる二通り」「人間が安心できるエビデンスをHTMLで提示」）

### Context
- ADR-008/009 で Inner Loop（`/auto-task` `/auto-bug`）は整備済みだが、「1タスク」より上の粒度（プロジェクト全体）を自律で運ぶ入口がなかった
- ユーザーの要求は2通りの入口: (A) プロンプト文のみ → 要件定義から生成、(B) 既存成果物（要件定義・設計の HTML/MD、プロトタイプ）→ 読み込んで開始
- 途中は人間レスで SOLID・TDD・レビュー収束（basic/deep）・テストピラミッド網羅（単体/結合/E2E）を守り、最後に人間が検証できるエビデンス（HTML）を提示する
- ADR-008 は「Outer Loop（時間駆動 cron）不採用」を決めているが、本件は**時間駆動ではなく1コマンド完結**であり Inner Loop 哲学の延長

### Decision
- **`/auto-build` を1本だけ新設**する（`auto-mvp` / `auto-product` の2本案は運用が面倒なため不採用。`--scope mvp|product` 引数で吸収、デフォルト mvp）
- フロー: 入力正規化（rdd.md）→ task-list → Sprintごと（task-detail + sprint/* ブランチ → Issueごとに auto-task）→ sprint→main PR 作成 → エビデンスレポート（HTML）生成 → 人間へ引き渡し
- **人間の関所は最小限の2箇所**: (1) モードAのみ rdd.md 生成直後の要件確認（要件ズレは全工程を無駄にするため）、(2) エビデンスを見て sprint → main のマージを判断する（AI は PR 作成まで）。加えて停止条件（同一 Sprint 内 2 タスク blocked / 危険変更チェック該当）で人間に制御を返す
- 既存スキルは**連鎖呼び出しのみ**（Harness 層不可侵、ADR-008 の設計原則を継承）
- 付随して `/auto-task` を強化: sprint/* 起動時の task/* 自動作成、bug 連鎖の問題解決志向化（複数案→試行→効果検証→ロールバック）、テストピラミッド全層の明記、Sprint 完了検知時の sprint→main PR 準備
- エビデンスは `doc/output/evidence/*.html`（build-context-site の仕組みを流用、自己完結 HTML）。「AIがやったと言っている」ではなく「人間が検証できる」（ログ・PR・コミット由来で出典を辿れる）形を必須とする

### Consequences
- (+) 「作って」の一言〜完成まで、既存 Harness/Loop 資産の連鎖だけで到達できる
- (+) dev-practices の「事後確認（Vibe Coding）」と接続: エビデンス確認 → 触って確認 → フィードバックは既存フローで受ける
- (−) 長時間ループになるため中断・再開（loop-state.md の二重管理: 全体=auto-build / タスク内=auto-task）の運用が前提
- (−) モードAの要件生成は AI 判断が混ざる → rdd.md に「AI判断」明記でトレース可能にして緩和

### Alternatives
- **`auto-mvp` と `auto-product` の2スキル**: ユーザー自身が「二つあったらめんどくさい」→ 1本 + `--scope` 引数に統合
- **Outer Loop（cron 駆動）で実現**: ADR-008 で不採用済み。1コマンド完結型で十分 → 不採用
- **エビデンスを MD で提示**: 人間の「安心して見られる」要求には閲覧性の高い自己完結 HTML が適合（L1/L4 の既存方針とも整合）→ MD 単体は不採用

---

## ADR-015: デザイン親ループ `/auto-design`（Figma/会話 → 型付きコンポーネント）

- **日付**: 2026-07-04
- **対象**: `.claude/skills/auto-design/SKILL.md`（新規）, `.claude/skills/auto-build/SKILL.md`（デザインIssueの振り分け配線）
- **出典**: 2026-07-04 セッションのユーザー要求（「Figmaからのデザイン→SSOTの一連もオートでできるものが欲しい」）

### Context
- デザインパイプラインは既存スキルで揃っている（design-ssot / design-mock → design-html → design-ui → design-components → design-assemble）が、毎回手動で連鎖させる必要があった
- ADR-014 の `/auto-build` はタスク実装の自律化のみで、デザイン系 Issue の受け皿がなかった
- デザインには dev-practices の「design TDD（発酵ループ）」があり、**触って確認する Vibe Coding が本質的に人間の仕事**

### Decision
- **`/auto-design` を新設**: 入口3通り（A: Figma → design-ssot / B: 会話 → design-mock / C: 既存SSOT JSON）から、確認用HTML → UI骨格 → コンポーネント分離 → 型付き結合 → 検証（bug時は問題解決志向のbug-*連鎖）→ basic/deep レビュー収束 → task→sprint 自律マージまでを1コマンドで運ぶ
- **人間の関所は Vibe Coding**: コード品質の収束は AI、体験の判断（触って「違う」）は人間。auto-task の関所（sprint→main マージ）とは関所の性質が異なることを明示
- SSOT を唯一の起点とし、Figma から直接コードを書くショートカットは禁止（トレーサビリティ維持）
- `/auto-build` の Sprint ループでデザイン系 Issue は `/auto-design` に振り分ける

### Consequences
- (+) Figma を渡すだけで再利用可能な型付きコンポーネントまで自律で到達できる
- (+) design TDD の発酵ループと接続: Vibe フィードバック → 該当ステップから再実行、で反復が回る
- (−) SSOT 抽出の精度は Figma 側の構造（命名・variants 整理）に依存する。乱れた Figma では人間の介入が増える

### Alternatives
- **auto-task にデザイン手順を吸収**: タスク実装とデザインパイプラインは連鎖するスキル群が別物で、1スキルが肥大化する → 分離を採用
- **design 系スキル自体にループを埋め込む**: ADR-008 の「Harness 層不可侵（親ループは連鎖呼び出しのみ）」に反する → 不採用

---

## ADR-016: template-feedback 取り込み（uilab3 + fable_test1 の送り状23項目）

- **日付**: 2026-07-05
- **対象**: `.claude/rules/*.md`（tool-usage / code-quality / dev-practices / context-management / git）、`.claude/skills/*/SKILL.md`（image-prep / testing / developer-specialist / creative-coder / basic-review / design-ssot / agent-browser / deep-review / task-run / template-feedback / project-init / auto-build / project-design-language）、新規 `.claude/skills/experience-plan/SKILL.md`・`.claude/skills/auto-mvp/SKILL.md`、新規 `.claude/hooks/git-branch-guard.sh`・`.claude/hooks/format-on-edit.sh`、`.claude/settings.json`
- **出典**: `../uilab3/doc/output/to-template.md`（項目1-7）、`~/fable_test1/doc/output/to-template.md`（項目1-16、発: aqualchemy）

### Context
- `/template-feedback` の定型走査（`ls ../*/doc/output/to-template.md`）で uilab3 の未取込7項目を検出
- ユーザーから追加で `~/fable_test1`（sibling ディレクトリの外、`../` の走査には入らない場所）の送り状を今回のスコープに含める指示があり、16項目を追加で走査
- 計23項目のスコープ確認を人間に取り、「両方全部を順に検討」で合意

### Decision
- **uilab3 7項目**: 全て反映。secret検証・pnpm非対話化・TLSラグは `tool-usage.md` へ、image-prep白線画レシピは `image-prep/SKILL.md` へ、vitest設定分離と不変条件テストは `testing/SKILL.md` へ、宣言的フォールバックは `developer-specialist/SKILL.md` へ
- **fable_test1 16項目**: 全て反映。うち以下は候補から調整:
  - 項目1（体験網羅プラン）: 候補は「新規skill or task-run追記」→ 新規 `experience-plan` skill を作成し `task-run` から参照する形に決定（他スキルからも再利用できるため）
  - 項目9（品質ゲート3層hook）: `git-branch-guard.sh`（main/master へのcommit/push を `exit 2` でブロック）と `format-on-edit.sh`（Prettier/ESLint --fix）を新規作成し `settings.json` に配線。lint/type-checkの重い検査はCI据え置き（hookに入れない）と判断
  - 項目15（auto-mvp新設）: ユーザーから「auto-mvpはMVP作成までで、本実装はauto-buildに引き継ぐ」と明示指示があり、スコープをauto-buildのモードC（`--from-mvp`）への引き継ぎまでに限定
  - 項目16（表現の演繹フレームワーク）: 出典は16行の長大な記述だったが、`template-feedback`項目13（スキル記述の最小主義）に従い、creative-coder（4つの問い）/ project-design-language（メタファー宣言欄）/ deep-review（未翻訳検出）へ要点のみ圧縮して分散配置

### Consequences
- (+) main への直接 push が仕組み（hook）でブロックされ、rules 文書頼みの規律から一段強化される
- (+) SSOT直書き検出→昇格、体験網羅チェックリスト等、レビュー品質をモデル性能に依存させない「宣言＋チェックリスト」パターンが複数スキルに横展開された
- (−) 新規hook（`format-on-edit.sh`）は `npx prettier`/`eslint` が無いプロジェクトでは無音でno-opになる（プロジェクト側にPrettier未導入だと効果が出ない → project-init のPrettier標準化とセット運用が前提）
- (−) auto-mvp は本実装を持たないため、単体では「動くプロトタイプ止まり」。auto-buildとの連携（`--from-mvp`）が前提の設計

### Alternatives
- 表現の演繹フレームワーク（項目16）を専用の新規skillとして独立させる案 → 既存skillの薄い追記で足りる内容であり、スキル数を増やすと `judgment-harness` のレイヤー構造が複雑化する → 既存skill分散配置を採用
- hookのlint/type-check強制も同時に実装する案 → プロジェクトごとにスクリプト名が異なり誤検知リスクがあるため、今回はbranch-guardとformatのみに限定し見送り

---

## ADR-017: project-init に CI セットアップ確認、課金操作の事前アラートを追加

- **日付**: 2026-07-05
- **対象**: `.claude/skills/project-init/SKILL.md`（3.3 CI確認ステップ）、`.claude/settings.json`（ask にデプロイ/公開系コマンド追加）、`.claude/rules/dev-practices.md`（課金前合意の禁止事項追記）
- **出典**: ユーザー要望（2026-07-05 セッション）。CI 雛形は fable_test1 の `.github/workflows/ci.yml`（git.md の CI 要件を実装した実績物）を汎用化

### Context
- `rules/git.md` に CI 要件（task/*→Lint+TypeCheck、main PR→+Build+Test）は定義済みだが、CI を実際にセットアップする工程がどのスキルにも無く、プロジェクトごとに手作りだった
- 課金が発生しうる操作（デプロイ・従量課金API）は auto-build/auto-task の「課金前停止ポイント」にはあるが、ループ外の通常作業では守る仕組みが無かった

### Decision
- `project-init` Phase 3.3 として「CI をセットアップしますか？」の確認ステップを追加。YES なら git.md 準拠の workflow を生成（スクリプト名・PMはボイラーの package.json に合わせて調整）
- デプロイ/公開系 CLI（npm publish / wrangler / vercel / firebase / aws / gcloud / terraform 等）を `settings.json` の ask に追加し、実行前にユーザー確認を機械的に挟む
- コマンド以外の課金経路（従量課金APIのコード内利用・有料SaaS前提の選定）は `dev-practices.md` の禁止事項として原則を追記（仕組みで拾えない範囲を文書で補完する二段構え）

### Consequences
- (+) 新規プロジェクトが最初から CI 要件と一致した workflow を持てる（fable_test1 実績の還流）
- (+) 課金操作は「ask（機械）＋原則（文書）」の二層でガードされる
- (−) `aws *` / `gcloud *` は読み取り系コマンドも ask になる（保守的に倒した。頻用するプロジェクトは settings.local.json で緩和する想定）

### Alternatives
- 課金アラートを hook（PreToolUse の warn）で実装する案 → 警告だけでは素通りできる。ask は承認そのものを要求するため permissions を採用
- CI workflow を独立ファイルとしてテンプレ同梱する案 → apply_template の配布対象が増え、CI 不要なプロジェクトにもコピーされる。project-init で「聞いてから生成」に寄せた

---

## ADR-018: デザイン適用タイミングの二択（先行/後行）を工程に組み込む

- **日付**: 2026-07-05
- **対象**: `.claude/rules/dev-practices.md`（発酵ループ節）、`.claude/skills/auto-build/SKILL.md`（Sprint 計画ステップ）
- **出典**: ユーザー要望（2026-07-05 セッション）。後行パターンの実績は fable_test1（sprint-1「遊べるコア」＝機能のみ → sprint-2「液体のエモさ」＝デザイン/表現。SSOT は sprint-2 で整備）

### Context
- design 系スキル群（design-ssot/design-mock → … → auto-design）は「デザインが先にある」前提の並びで、fable_test1 のような「機能を先に成立させ、デザインを後から適用する」流れの置き場所が工程上どこにも無かった
- 後行にする場合、実装が色・文言を直書きしていると適用時に書き直しになる（先行/後行の分岐は実装規約に影響する）

### Decision
- dev-practices の発酵ループ節に「先行/後行の二択を人間が選ぶ」を明記。選び方の判断軸（見た目の合意が先に必要か / 機能の成立が先に検証したいか）と、後行時の実装規約（SSOT参照の仮値・セマンティック構造で書き、適用を差し替えで済ませる）を追加
- auto-build の Sprint 計画に判定を組み込み: SSOT/Figma/デザイン要件が既にあれば先行（design 系 Issue を最初から）、無ければ 🛑 人間に先行/後行を確認する停止条件を追加

### Consequences
- (+) fable_test1 で暗黙にやっていた「機能→デザイン」の二段構えが、明示的な選択肢として工程に乗る
- (+) 後行時の実装規約により、デザイン適用が「SSOT差し替え」で済む（直書きの書き直し地獄を防ぐ）
- (−) auto-build の人間関所が1つ増える（UI ありでデザイン入力が無い場合のみ）

### Alternatives
- 常にデザイン先行を強制する案 → プロトタイプ駆動（着手時点で人間も答えを持たない）と矛盾。機能検証が先のプロジェクトで空回りする → 二択を人間に委ねる形を採用
- auto-design 側にタイミング判定を持たせる案 → auto-design は「デザイン実装の実行」担当で、いつやるかは Sprint 計画（auto-build）の責務。判定は auto-build に置いた

---

## ADR-019: template-feedback 取り込み（sonnet_test: 描画技術選定の既定値）

- **日付**: 2026-07-05
- **対象**: `.claude/skills/creative-coder/SKILL.md`（描画技術選定の節を新設）、`.claude/skills/architecture-expert/SKILL.md`（非機能チェックリストに1行）
- **出典**: `../sonnet_test/doc/output/to-template.md` 項目1（実測比較: sonnet_test と fable_test1 が同一課題で独立に Canvas 2D を手書きした事例。fable_test1 の `src/render/liquid-renderer.ts` 実在を確認済み）

### Context
- 描画技術選定のルールが無いと、異なるモデルが独立に Canvas 2D を手書きし、車輪の再発明と CPU 律速の性能上限を各自で抱える（2プロジェクトの実測で確認）
- 送り状の反映先候補は5箇所（rules 新節 / creative-coder / frontend-implementation / architecture-expert / CLAUDE.md 一行）だった

### Decision
- **creative-coder に判断軸を集約**: 「描画量 × 更新頻度」マトリクス、WebGL オフロード既定、計測してから最適化、ドメインロジックの描画分離、ドグマ化しない注意
- **architecture-expert に1行参照**: 非機能チェックリストから creative-coder の判断軸へ誘導
- rules 新節・CLAUDE.md 追記は**見送り**（常時読込の肥大化回避。「rules は薄く・最小で」原則）
- frontend-implementation への追記も**見送り**（同スキルは「技術は別skillに委ねる」と自己宣言しており領分外）

### Consequences
- (+) どのモデルでも「ライブラリ＋WebGL既定」の同じ判断に収束する（ADR-007 モデル非依存と整合）
- (+) 判断軸が1箇所（creative-coder）に集約され、他スキルは参照で辿れる
- (−) creative-coder が発火しない文脈（純バックエンド寄りの相談から描画に波及した場合等）では届かない可能性 → architecture-expert の参照行で補完

### Alternatives
- 送り状候補どおり5箇所に反映する案 → rules/CLAUDE.md の肥大化、同内容の重複記載で保守コスト増 → 集約＋参照を採用

---

## ADR-020: プロト工程を連作ループ化（auto-mvp → proto-loop）＋媒体判断ガイド新設

- **日付**: 2026-07-18
- **対象**: `.claude/skills/proto-loop/`（旧 auto-mvp を改修・リネーム）, `.claude/skills/proto-medium/`（新設）, `.claude/skills/project-design-language/`, `.claude/skills/auto-build/`, `.claude/rules/dev-practices.md`
- **出典**: `doc/generated/reports/2026-07-18-proto-workflow-proposal.html`（承認済み提案・図解つき）

### Context
- auto-mvp の「プロンプト1文 → 無指示で2〜4案並列発散」は、体験設計・世界観にこだわる作り方と噛み合わなかった（「何も命令しないで3つ作って」は違う、という実感）
- 案と案の間で学びが継承されず、選定時に一度言語化されるだけだった
- AI動画制作の作法（キャラ設定資料を作り、出力を見て資料とプロンプトを磨いてから本番）が、アイディアを練る過程を大事にする形として参考になった
- 「これはFigmaでやるべきか、コードで作るべきか」の判断基準を人間側がまだ持っておらず、ガイドが必要だった
- 個人のデザイン知識ベース（design-brain）を活かしたいが、ai-template は OSS なので個人の審美眼を配布物に埋め込めない

### Decision
- **auto-mvp を proto-loop に置き換え**（共存させず入口を一本化。`--from-mvp` は旧称エイリアスとして注記のみ残す）
- ループ構造: 問いを立てる（人間と・毎ラウンド必須）→ 媒体選択 → 制作（1プロト＝1エージェント・文脈遮断）→ Vibe確認 → **設定集（Setting Book）へ蒸留** → 反復 → 統合プロト → auto-build 引き継ぎ → 本番終盤の磨きラウンド
- **設定集**は `doc/input/design/setting-book/` に置く発酵場所（採用/不採用の表現・プロンプト集を含む、ビジュアル付き資料）。確定判断のみ project-design-language（SSOT）へ昇格 — judgment-harness の「メモとSSOTを分ける」に整合
- **並列は「比較軸が明確なラウンドでの2案」のみ許可**（「並行して作って統合したい」と「無指示で3つは違う」の両立点）
- **proto-medium（判断軸スキル）新設**: 核は「止まっている絵で判断できるなら Figma、動かさないと分からないならコード」。AIが毎回推奨＋理由を提示し人間が承認する運用（理由の言語化を通じて人間側の判断力も育てる）
- **design-brain 連携は「参照欄」方式**: project-design-language 雛形に外部知識ベース欄（パス・優先順・任意記入）だけを置き、中身は各自の環境に分離（グローバル/配布物の置き場所方針と同型）

### Consequences
- (+) 学びがラウンドごとに設定集へ蓄積され、後のプロトほど的が絞れる。アイディアを練る過程が成果物として残る
- (+) Figma/コードの使い分けが毎回言語化され、人間の判断基準が育つ
- (+) 個人の審美眼（design-brain）と OSS 配布物が汚染なく接続できる
- (−) 1ラウンドごとに人間の関与（問い立て・Vibe確認）が必須になり、無人で数を出す速度は落ちる（「速さより意図」の方針に整合するため許容）
- (−) 設定集の維持コストが増える（更新をラウンドの必須手順に組み込んで揮発を防ぐ）
- 使いながら「違う」と感じたら変更する前提（この ADR は現時点の仮説。改訂時は新 ADR で上書きし、経緯を残す）

### Alternatives
- auto-mvp と proto-loop の共存 → 入口が2つになり「どちらを使うか」の判断が毎回発生する。旧動作（無指示発散）は残す価値が薄いと判断し置き換え
- 常に1本ずつ（並列全面禁止）→ トーン比較のような「並べて見ないと分からない」検証で不便。軸の明示を条件に2案並行を許可
- design-brain の中身をテンプレに同梱 → OSS に個人の審美眼が流れる。参照欄方式で分離
- 媒体判断を proto-loop 本文に埋め込む → デザイン検討全般（プロト以外）でも使う判断軸なので独立スキルに切り出し

---

## ADR-021: 送り状取り込み（listening-editor）— ガード系フックの fail-closed 化と外部依存の配布方針

- **日付**: 2026-08-09
- **出典**: `doc/input/from-projects/listening-editor.md`（送り状インボックス）/ `~/output/listening-editor-workspace`（解決済み実物）

### Context
- `git-branch-guard.sh` は main への直接 commit/push をブロックする建て付けだったが、**実測すると危険ケース6件すべてが exit 0 で素通り**していた。ガードが無いのに「守られている」と誤認していた状態
- 原因は独立して3つ。(A) `\bgit (commit|push)\b` が `git -C <path> commit` を取り逃がす（AIは cwd を動かさずに済む `-C` 形を好むため、人間の手癖前提のパターンは抜ける）(B) `rev-parse --abbrev-ref HEAD` はコミット0件のリポジトリで文字列 `HEAD` を返し、初回コミットの瞬間だけ穴が開く (C) フックは実行「前」に走るため cwd が対象リポジトリと一致しない
- あわせて、配布物が外部MCPに依存する際、設定ファイルに同梱すると利用者環境で二重登録が起きる事例があった

### Decision
- フック本体は listening-editor で**実測済みの実物を写す**（送り状の記述から書き直さない。検証済み内容の劣化を避ける）
- **fail-closed 化**: ブランチを特定できないときは exit 2 で止める
- **検証スクリプトを配布物に同梱**（`.claude/hooks/test-git-branch-guard.sh`）。一時リポジトリを自前で作り、通す/止める両方を10ケース叩く。送り状のスニペットは `<repo>` プレースホルダのままだったため、実行可能な形に仕上げた
- 原則は `.claude/rules/tool-usage.md` に4点だけ薄く追記。外部依存の配布方針は `.claude/rules/code-quality.md` へ

### Consequences
- (+) 修正後は10/10 PASS、修正前は4/10（危険ケース6件すべて素通り）。差が実測で残った
- (+) 以後フックを触るたびに `bash .claude/hooks/test-git-branch-guard.sh` で回帰確認できる
- (−) fail-closed により、Git管理外ディレクトリからの `git commit` は止まるようになる（`git -C <path>` でリポジトリを明示すれば通る）
- (−) 配布物が1ファイル増える。ガードの信頼性と引き換えに許容

### Alternatives
- 送り状の記述だけを頼りにフックを書き直す → 実測で3原因に切り分けた成果が劣化する。実物を写す方を採用
- 検証スクリプトを同梱せず tool-usage.md に手順を文章で書く → 「書いて終わりにしない」原則が仕組みで担保されない。同梱を採用
- 原因Aだけ直す → 出典セッションでも同じ失敗をしている（最初の修正はテストで落ちた）。3原因すべてと refspec 側のもう1箇所を同時に直す

---

## ADR-022: 投函箱をPCローカル化し、構築コマンド（/template-inbox）を新設

- **日付**: 2026-08-09
- **関連**: ADR-021（投函箱経由での初回取り込み）

### Context
- ADR-021 で `doc/input/from-projects/`（投函箱）を Git 追跡＋コミットしたが、**実測すると配布物にそのまま混入**していた。`apply_template.sh` の配布対象は `doc/input/` 丸ごとで、投函箱を除外していなかった
- 混入していたのは (1) 他プロジェクトの受信データそのもの (2) `/Users/<user>/...` のローカル絶対パス (3) private リポジトリの URL
- 投函箱は取り込むたびに増えるため、放置すると配布物が単調に膨らむ
- 絶対パスは欠陥ではなく**投函箱の価値の源**（取り込み時に実物を読める。ADR-021 で実際にこれが効いた）。相対表記に直すと価値が落ちる
- 新しいマシンで clone すると、追跡外にした投函箱は空になる

### Decision
- **投函箱の実体は Git 追跡外**（`.gitignore` で `doc/input/from-projects/*.md`、`README.md` のみ追跡）。仕組みの説明は配布し、受信データは配布しない
- **配布物からも除外**（`apply_template.sh` で `from-projects/` を exclude）。公開（GitHub）と配布（apply_template）は別経路なので**両方に手当てが要る**
- 絶対パスはローカル専用ファイル内でそのまま維持する（実物を読める利点を優先）
- **`/template-inbox` を新設**: sibling を走査し、そのPCの実際の配置から投函箱を materialize する。`/template-feedback` の前段に置き、投函箱が `README.md` だけなら先に実行するよう導線を張った
- `meta/adr-lite.md` の絶対パスは `~/` 表記に統一（配布対象外だが GitHub では公開されるため）
- 同じ構造の問題として **`doc/generated/reports/` も配布対象外**にした（ai-template 自身の作業記録が全プロジェクトへ複製され増え続けるため）。ディレクトリ自体は残し、配布先が最初から置き場所を持てるようにする

### Consequences
- (+) 配布物・公開物から個人固有のパスと受信データが消えた（実測: 配布先に `from-projects/` ディレクトリ自体が作られない）
- (+) 投函箱が増えても配布物は膨らまない
- (+) 「ai-template を開けば未処理の学びが目に入る」という投函箱の主目的は維持される（ローカルにファイルは残るため）
- (−) 「ai-template を push すれば他マシンからも未処理の学びが見える」という副次的利点は失われる。`/template-inbox` で組み直す運用で代替する
- (−) 工程が1つ増える（構築 → 取り込み）。ただし責務が分かれて各コマンドは薄くなった

### Alternatives
- `apply_template.sh` の除外だけで済ませる → GitHub 上には残る。公開と配布の両方を塞ぐ必要がある
- 絶対パスを `~/` 表記に変えて追跡を続ける → ユーザー名は消えるが受信データ自体が配布物に残る。増え続ける問題も解決しない
- 取込済の送り状を削除して未取込だけ追跡 → 「個人の受信箱を公開物に置く」構造は変わらない
- `/template-feedback` に構築ステップを内包 → 取り込みの手順が厚くなる。厚いスキルは誤読・過剰実行を誘発するため分割した

---

## ADR-023: 同じ欠陥の横展開点検 — warn-destructive-bash も AI形コマンドを素通りしていた

### Context
- ADR-021 で `git-branch-guard.sh` を fail-closed 化した際、根本原因のひとつが「人間の手癖（`cd` してから `git`）を前提にした正規表現が、AIの好む `git -C <path>` 形を取りこぼす」ことだった
- `tool-usage.md` に「**同じ欠陥はファイル内に複数ある前提で探す**」を書いたが、**ファイルをまたいだ横展開の点検は未実施**だった
- PreToolUse(Bash) にはもう1つ `warn-destructive-bash.sh` が登録されており、`git reset --hard` 等の破壊的コマンドを警告する役割を持つ

### Decision
- 同じ21ケースで実測したところ **15/21 PASS**。`git -C` 形の4件（force push / reset --hard / clean -fd / checkout .）が全て素通りしていた。加えて `rm -fr`（オプション順違い）の見落としと、`git push origin my-feature` をブランチ名の `-f` で誤検知する問題も発見
- **判定前に `git -C <path>` を `git` へ正規化する**方式を採用。パターン側を1つずつ `-C` 対応に書き換えるのではなく、入口で人間形・AI形を同じ土俵に乗せる（パターンが増えても穴が再発しない）
- オプション部を `[^;&|]*` で受け、パイプ・コマンド連結をまたいだ誤検知を防ぐ
- 検証スクリプト `test-warn-destructive-bash.sh` を同梱（21ケース、**修正後 21/21 PASS**）。「誤検知してはいけない普段使い」7件を含め、締めすぎの副作用も測る

### Consequences
- (+) 破壊的コマンドの警告が、AIが実際に打つ形でも働くようになった（実測 15/21 → 21/21）
- (+) 正規化方式なので、今後パターンを足すときに `-C` 対応を忘れても穴にならない
- (+) 誤検知1件も同時に解消（ブランチ名に `-f` を含む通常 push が警告されなくなった）
- (−) 検証スクリプトが2本になった。フックを増やすたびに検証も増える運用コストは受け入れる（無検証のガードは「守られているつもり」を生むため）
- **未解決として記録**: `settings.json` の `permissions.ask`（`Bash(git reset *)` 等）も同じ前置詞問題を持つ可能性がある。`git -C <path> reset --hard` がプレフィックス照合に一致するかは Claude Code 側の実装依存で、**未検証**。フック側で警告が出るため二重の守りは効いているが、確認する価値がある

### Alternatives
- パターンを1つずつ `git( -C \S+)?` 形に書き換える → 記述が冗長になり、追加時の書き忘れが穴になる。正規化なら入口1箇所で済む
- warn を block（exit 2）に格上げする → 破壊的操作は正当な場合も多く、止めると作業が回らない。止めるのは `git-branch-guard.sh`（main保護）の責務と分離を維持
- 点検だけして記録し修正は次回に回す → 欠陥が実測で確定している以上、放置は「守られているつもり」を継続させる
