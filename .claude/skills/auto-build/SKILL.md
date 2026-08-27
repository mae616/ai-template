---
user-invocable: true
description: "プロンプト文または既存成果物（要件定義・設計のHTML/MD）から、Sprint計画 → 全タスク自律実装 → sprint→main PR → エビデンスレポート（HTML）生成までを1コマンドで完結する。Loop Engineering の最上位親スキル。"
---

# [ループ] 自律ビルド `/auto-build`

> Loop Engineering の最上位親スキル。既存のループ層スキル（task-list / task-detail / auto-task / auto-bug）を**連鎖呼び出し**して、「作って」から「完成＋エビデンス提示」まで自律で運ぶ。スキル本体は触らない（Harness 層不可侵）。
>
> 設計根拠: `meta/adr-lite.md` の **ADR-008 / ADR-014**
>
> 人間の関所は**最小限の2箇所**: (1) プロンプト起点（モードA）のみ、rdd.md 生成直後の要件確認 / (2) エビデンスレポートを見て sprint → main のマージを判断する。

## 入力: $ARGUMENTS

2通りの入口を受け付ける:

| モード | 入力例 | 動き |
|---|---|---|
| **A: プロンプト** | `/auto-build "家計簿アプリを作って"` | AI が要件定義（rdd.md）から起こす |
| **B: 成果物** | `/auto-build doc/input/設計.md` | 既存の要件定義・設計（HTML/MD・プロトタイプ）を読み込んで開始 |
| **C: proto-loop選定結果** | `/auto-build --from-proto <設定集パス>` | `proto-loop` で連作・統合した結果（設定集＋統合プロト）を rdd.md の種として取り込み、TDD で作り直す（プロトのコード再利用は最小限。`--from-mvp` は旧称エイリアス） |

オプション（省略時は `mvp`）:
- `--scope mvp`: MVP（最小の動く価値）までを計画・実装する
- `--scope product`: 要件全体（非機能・磨き込み含む）までを計画・実装する

---

## 🎯 目的

- 人間が途中に関わらなくても、**SOLID 原則・TDD・レビュー収束・テストピラミッド網羅**を守った実装をゴールまで運ぶ
- 最後に人間が**安心して判断できるエビデンス**（HTML レポート）を提示する
- 中断してもどこからでも再開できる（`history/loop-state.md`）

---

## 前提（必ず確認）

- GitHub リポジトリ・gh CLI が使える状態であること
- 課金が発生しうる操作（新規パッケージインストール、リモートデプロイ、外部 API 課金）は**事前にユーザーへ確認**して止まる（`/auto-task` と同じ方針）
- **sprint → main は絶対に自律マージしない**（人間の唯一の関所）

---

## 実行手順

### 0. ループ状態ファイルの初期化

`history/loop-state.md` を以下で開始（既存なら追記）:

```markdown
## YYYY-MM-DD HH:MM /auto-build <入力の要約> (--scope <mvp|product>)
- status: in_progress
- steps:
  - [ ] project-init-check (未初期化なら project-init 連鎖)
  - [ ] input-normalize (rdd.md 準備)
  - [ ] task-list (Sprint計画)
  - [ ] sprint-loop (Sprintごとの実装。進捗は sprint 単位で追記)
  - [ ] evidence-report (HTML生成)
  - [ ] handoff (人間への提示)
- last_action: ループ開始
```

各ステップ完了時に `[x]` 更新と `last_action` 書き換え（ADR-012 の中断時復帰の鍵）。

---

### 1. プロジェクト初期化判定

実行ディレクトリが**未初期化**（判定基準: `package.json`/`pyproject.toml` 等のプロジェクト定義ファイルが無い、または `src` 相当が空）の場合、Sprint 計画へ進む前に **`project-init` を連鎖**し、公式推奨ボイラーテンプレート（`npm create` 等）からプロジェクトを作成する。対話式コマンドは `.claude/rules/tool-usage.md` の対話式コマンドガイドに従い、ユーザー手動実行を案内する。既に初期化済みならスキップする。

---

### 2. 入力判定 → rdd.md 準備

**モードA（プロンプト文）**:
1. プロンプトから「目標 / 非目標 / 想定ユーザー / 技術スタック / 非機能要件」を骨子に起こす
2. 不明点は**推測で埋めず**、妥当なデフォルトを選んだ場合はその旨を rdd.md に「AI判断」として明記する（後からエビデンスで追える状態にする）
3. `doc/input/rdd.md` として書き出す（既存があれば追記・更新の確認を取る）
4. **🛑 停止条件（要件の関所）**: rdd.md の要約を提示して**人間の GO を待つ**。要件のズレは以降の全工程を無駄にするため、モードAではここで必ず1回止まる（モードBは既存成果物が要件の合意物なのでスキップ可）

**モードB（成果物パス）**:
1. 指定された HTML / MD / プロトタイプを読み込む
2. `doc/input/rdd.md` の形式（目標・非目標・技術スタック・非機能要件）に**正規化**する
3. 成果物と rdd.md の対応関係（どのセクションが出典か）を rdd.md 内に記録する

> どちらのモードでも、以降のループの SSOT は `doc/input/rdd.md`。

---

### 3. Sprint 計画（task-list 連鎖）

- **デザイン適用タイミングの判定**（UI を持つプロジェクトのみ）:
  - デザインSSOT（`doc/input/design/*`）・Figma参照・rdd.md のデザイン要件が**既にある** → **先行**: design 系 Issue を最初の Sprint から含める（実装は `auto-design` 連鎖）
  - **無い** → **🛑 人間に確認**: 先行（`design-mock` で叩き台から固める）か、後行（機能 Sprint を先に回し、機能の Vibe 確認後にデザイン Sprint を計画）かを選んでもらう。後行の場合、機能実装は `dev-practices.md` の後行時実装規約（SSOT参照の仮値・セマンティック構造）で進める
  - **判定・選択の結果（先行/後行）は `doc/input/rdd.md` に「デザイン適用タイミング」として記録する**（連鎖先 `auto-task` の停止要否判定と、中断再開時の根拠になる。会話の文脈だけに残すと再開後に判定できない）
- **project-design-language の起票確認**（UI を持つプロジェクトのみ）: `.claude/skills/project-design-language/SKILL.md` が**雛形のまま**（基本方針が `{...}` / TBD）なら、デザイン実装に入る前に埋める工程を計画へ組み込む:
  - **先行**の場合 → この場で `judgment-harness` の発酵ループに従い、基本方針（誰のため/北極星/単一メタファー）を人間と対話で埋めてから design 系 Issue へ進む
  - **後行**の場合 → デザイン Sprint の先頭に「project-design-language 起票」Issue を作成する（機能 Sprint 中は TBD のままでよい）
- `task-list` の手順に従い、rdd.md から Milestone（Sprint）と Issue を一括作成
- `--scope mvp` の場合は **MVP に必要な Sprint のみ**計画する。`--scope product` は要件全体を Sprint に分割
- 組み込み Task にも登録（並行・依存管理）

---

### 4. Sprint ループ（Sprintごとに反復）

各 Sprint について以下を順に実行する:

1. **`task-detail` 連鎖**: Sprint 内の全 Issue を詳細化（実装ブループリント・依存関係・`ready-for-dev`）し、`sprint/*` ブランチを作成
2. **タスクループ**: `ready-for-dev` な Issue を**依存関係順**に `auto-task` 連鎖で実行
   - **デザイン系 Issue**（画面・UIコンポーネント実装。Figma 参照や SSOT を持つもの）は `auto-task` の代わりに **`auto-design`** を連鎖する
   - 実装（SOLID 遵守）→ テストピラミッド全層（単体/結合/E2E）→ bug 検知時は問題解決志向の bug-* 連鎖で自己修復して復帰 → basic-review 収束 → deep-review 収束 → task→sprint 自律マージ
   - 依存が独立な Issue はサブエージェントで並行実行してよい（結果の整合は統合時に確認）
3. **Sprint 完了検知**: 全タスクマージ後、`auto-task` ステップ9に従い **sprint → main の PR を作成**（マージはしない）

**Sprint 単位で `history/loop-state.md` に進捗を追記**（`sprint-1: completed (PR #42)` の形式）。

**🛑 停止条件（blocked タスクの扱い）**:
- あるタスクが blocked（bug 連鎖 3周超え / レビュー反復上限超え / 危険変更チェック該当）になった場合:
  - そのタスクに**依存しない**他タスクは続行してよい
  - blocked タスクに**依存する**タスクには着手しない
- **同一 Sprint 内で 2 タスクが blocked になったら Sprint ループ全体を停止**し、`history/loop-state.md` に状況を記録して人間へ報告する（構造的な問題（要件・設計のズレ）の兆候であり、押し切ると傷が深くなるため）

---

### 5. エビデンスレポート生成（HTML）

全 Sprint 完了後（または `--scope mvp` の範囲完了後）、人間の判断材料を1つの HTML に集約する。

- **出力先**: `doc/output/evidence/YYYY-MM-DD-<プロジェクト名>.html`
- **生成方法**: `build-context-site` の仕組み・スタイルを流用（自己完結 HTML、外部依存なし）

**必須コンテンツ**:

| セクション | 内容 |
|---|---|
| 要件・設計 | rdd.md の要約と全文リンク、AI判断で埋めた箇所の一覧、アーキテクチャ概要（構成図） |
| Sprint / タスク | Sprint一覧、各 Issue と対応 PR、依存関係グラフ |
| レビュー履歴 | basic-review / deep-review の**反復回数と指摘数の推移**（例: basic 3周 8→2→0件）、主要指摘と対応内容 |
| テスト結果 | 単体 / 結合 / E2E の実行結果・件数・カバレッジ。実行コマンドと生ログへの参照 |
| bug 対応記録 | bug-* 連鎖の発動回数、試した修正案と採否、ロールバック履歴 |
| 判断待ち | sprint → main の PR 一覧（リンク）、`ai-merged-unreviewed` ラベルの残数 |

> 原則: **「AIがやったと言っている」ではなく「人間が検証できる」**形で載せる。テスト結果は実行ログ由来、レビュー履歴はコミット・PR コメント由来で、出典を辿れるようにする。

---

### 6. 人間への引き渡し（handoff）

1. エビデンスレポートのパスを提示し、内容の要約（3〜5行）を添える
2. sprint → main の PR 一覧と「マージ判断をお願いする」旨を明示
3. `history/loop-state.md` を `status: completed` に更新
4. Vibe Coding（人間が実際に触る確認）を促す。フィードバックが出たら通常フロー（タスク化 → `/auto-task` or `/auto-bug`）で受ける

---

## 課金前停止ポイント

`/auto-task` と同じ（新規パッケージ・リモートデプロイ・有料外部 API・有料 CI）。加えて:

- **モードAで技術スタックを AI が選定する場合**、有料 SaaS を前提にする選定は**事前確認**して止まる

---

## 中断・再開

- `history/loop-state.md` の `last_action` と Sprint 単位の進捗記録から再開位置を判定
- 手動再開は `/auto-build` を再起動（同じ rdd.md があれば入力判定をスキップして続きから）
- `/auto-task` 単位の中断は auto-task 側の loop-state 記録が生きる（二重管理: 全体は auto-build、タスク内は auto-task）

---

## やってはいけない

- sprint → main の自律マージ（唯一の人間の関所を壊さない）
- rdd.md の不明点を**推測で埋める**。記録すれば埋めてよい、ではない。
  不明点は**短問で確認する**か、`doc/draft/` に候補として置いて合意を待つ。
  やむを得ず仮置きする場合は「AI判断・未合意」と明記し、**合意を得るまで確定扱いしない**（ADR-027）
- テストが通らない・レビューが収束しないまま次の Sprint へ進む
- エビデンスに検証不能な主張を載せる（出典・ログのないテスト結果、実在しないリンク）
- 課金発生ポイントの確認スキップ
- `history/loop-state.md` の更新を怠る

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {Sprint数・bug連鎖発動回数・レビュー反復回数・エビデンスの網羅度を踏まえて記載}
