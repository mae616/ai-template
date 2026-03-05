---
user-invocable: true
description: "壁打ちから要件定義、ボイラーテンプレート作成、AIテンプレート適用までを一気通貫で実行する。新規プロジェクトの立ち上げで使う。"
---

# [プロジェクト] 新規プロジェクト初期化

## 入力:
- プロジェクトの概要（任意）
- 省略時: 壁打ちから開始

例:
    新しいポートフォリオサイトを作りたい
    SaaSダッシュボードを始めたい
    Astro + Svelte でブログを作りたい

---

## 🎯 目的
- 要件定義からプロジェクト作成までを**壁打ちしながら一気通貫**で実施
- ボイラーテンプレートの作り方を毎回調べる手間をなくす
- ai-template（.claude/ CLAUDE.md doc/）を**自動適用**し、rdd.md に要件定義を反映した状態で開発を開始

---

## Phase 0: テンプレートソースの検出

> このスキルは ai-template ディレクトリ内から実行しても、グローバルスキルとしてどこからでも実行しても動く。

### 検出ロジック（AIが自動実行）

```bash
# 1. カレントディレクトリが ai-template か確認
if [ -f "./CLAUDE.md" ] && [ -d "./.claude/skills/project-init" ]; then
  TEMPLATE_SOURCE="$(pwd)"

# 2. グローバル設定ファイルから読み取り
elif [ -f "$HOME/.claude/ai-template-path" ]; then
  TEMPLATE_SOURCE="$(cat $HOME/.claude/ai-template-path)"

# 3. よくあるパスを探索
elif [ -d "$HOME/output/ai-template/.claude/skills" ]; then
  TEMPLATE_SOURCE="$HOME/output/ai-template"

# 4. 見つからない → ユーザーに確認
else
  # AIがユーザーにパスを質問する
  echo "ai-template のパスを教えてください"
fi
```

### テンプレートパスの永続化（初回のみ）
見つかったパスを `~/.claude/ai-template-path` に保存して、次回以降自動検出できるようにする。
ユーザーに保存の確認を取ること。

---

## Phase 1: 壁打ち（`/pair plan` と同じ進め方）

> `/pair` スキルと同じ壁打ちスタイルで進める。推測で断言せず、前提・選択肢・トレードオフを言語化する。

### 適用skill（ガイド）
- `biz-researcher` / `proposition-reviewer`（事業仮説・ターゲットの整理）
- `architecture-expert`（技術選定・アーキテクチャ判断）
- `ui-designer`（UIが中心のプロジェクトの場合）

### 進め方（`/pair` と共通）

**ステップ1: 不足情報を短問で確認（1〜3問）**

プロジェクト概要を聞き、以下の不足を埋める:

| 確認ポイント | rdd.md の対応セクション |
|-------------|----------------------|
| 何を作る？誰のため？ | プロジェクト概要 > 目的・想定ユーザー像 |
| どこで動く？ | ターゲット表示環境 |
| 制約は？（期限/体制/予算） | 制約 |

**ステップ2: 技術スタックを2〜3案提示（トレードオフつき）**

| レイヤー | 選定基準 |
|---------|---------|
| **フロント** | ターゲット環境・インタラクション要件・SSR/SSG要否 |
| **バックエンド** | API要件・リアルタイム要否・認証要件 |
| **データ** | 永続化要件・スケール・コスト |
| **インフラ** | デプロイ先・CI/CD・コスト |
| **テスト** | テスト戦略（Unit/Integration/E2E） |

**ステップ3: 推奨案と理由**

採用する技術スタックの推奨案を、根拠とともに提示する。

**ステップ4: rdd.md ドラフト生成 → 次の一手**

壁打ちの結果を `doc/input/rdd.md` のフォーマットに整形する。
この時点ではメモリ上に保持（ファイル書き込みは Phase 3 で行う）。

ドラフトをユーザーに見せて「この内容でプロジェクトを作成しますか？」と確認する。
承認後、Phase 2 へ進む。

---

## Phase 2: ボイラーテンプレート作成

### 2.1 プロジェクト名・ディレクトリの決定

```
質問:
- プロジェクト名（slug形式）は？ 例: my-portfolio, saas-dashboard
- 作成先ディレクトリは？ 例: ~/output/, ~/projects/
```

### 2.2 ボイラーテンプレートの選定

Phase 1 で決めた技術スタックに基づき、CLI コマンドを提案する。

#### よく使うボイラーテンプレート一覧

| 技術スタック | CLIコマンド | 補足 |
|-------------|-----------|------|
| **Astro** | `npm create astro@latest` | 対話式。テンプレート選択あり |
| **Next.js** | `npx create-next-app@latest` | App Router/Pages Router選択 |
| **Remix** | `npx create-remix@latest` | テンプレート選択あり |
| **SvelteKit** | `npx sv create` | テンプレート選択あり |
| **Vite + React** | `npm create vite@latest -- --template react-ts` | 軽量。SPA向き |
| **Vite + Svelte** | `npm create vite@latest -- --template svelte-ts` | 軽量。SPA向き |
| **Vite + Vue** | `npm create vite@latest -- --template vue-ts` | 軽量。SPA向き |
| **Express** | `npx express-generator` | バックエンド単体 |
| **Hono** | `npm create hono@latest` | 軽量エッジバックエンド |
| **T3 Stack** | `npm create t3-app@latest` | Next.js + tRPC + Prisma + Tailwind |
| **Turborepo** | `npx create-turbo@latest` | モノレポ。複数パッケージ管理 |

> 上記にない場合は、技術スタックに合った公式 CLI を Web 検索で確認する。

### 2.3 ボイラーテンプレートの実行

1. ユーザーにCLIコマンドを提示して確認を取る
2. 承認後、`Bash` ツールで実行する
3. 対話式プロンプトがある場合は、Phase 1 の決定事項を基に選択肢を案内する

**注意**:
- CLIの対話式プロンプトは自動応答が難しい場合がある。その場合はユーザーに手動実行を案内する
- 実行前に必ず `ls` で作成先ディレクトリの存在を確認する
- TypeScript を使う場合は TS テンプレートを優先する

### 2.4 依存パッケージの確認

ボイラーテンプレート作成後:
1. `package.json` 等を確認して、追加で必要なパッケージを提案する
2. Phase 1 で決めた技術スタックに基づき、追加インストールを実行する

---

## Phase 3: AIテンプレートの適用

### 3.1 コピー対象

Phase 0 で検出した `TEMPLATE_SOURCE` から、以下をコピーする:

| コピー元 | コピー先 | 説明 |
|---------|---------|------|
| `.claude/skills/` | `.claude/skills/` | 判断軸・手順系スキル一式 |
| `.claude/settings.json` | `.claude/settings.json` | Claude Code 設定（存在する場合） |
| `CLAUDE.md` | `CLAUDE.md` | プロジェクトルール |
| `.claude/rules/` | `.claude/rules/` | 運用ルール（自動適用） |
| `doc/input/rdd.md` | — | コピーしない（Phase 3.2 で生成する） |

### コピーコマンド例

```bash
TEMPLATE_SOURCE="/path/to/ai-template"
PROJECT_DIR="/path/to/new-project"

# ディレクトリ構造を作成
mkdir -p "$PROJECT_DIR/.claude"
mkdir -p "$PROJECT_DIR/.claude/rules"
mkdir -p "$PROJECT_DIR/doc/input"

# skills をコピー（既存があればマージ）
cp -r "$TEMPLATE_SOURCE/.claude/skills" "$PROJECT_DIR/.claude/"

# 設定ファイルをコピー（存在する場合のみ）
[ -f "$TEMPLATE_SOURCE/.claude/settings.json" ] && cp "$TEMPLATE_SOURCE/.claude/settings.json" "$PROJECT_DIR/.claude/"

# CLAUDE.md をコピー
cp "$TEMPLATE_SOURCE/CLAUDE.md" "$PROJECT_DIR/"

# 運用ルールをコピー
cp -r "$TEMPLATE_SOURCE/.claude/rules/" "$PROJECT_DIR/.claude/rules/"
```

### 3.2 rdd.md の生成

Phase 1.3 で作成したドラフトを `doc/input/rdd.md` に書き出す。

```bash
# rdd.md を Write ツールで生成
# Phase 1 のドラフト内容を doc/input/rdd.md に書き込む
```

### 3.3 .gitignore の確認

ボイラーテンプレートの `.gitignore` に以下が含まれているか確認し、なければ追記する:

```
# セッション一時ファイル
.claude/session-context.md

# 環境変数（セキュリティ）
.env
.env.local
.env.*.local
```

---

## Phase 4: 初期化完了と案内

### 4.1 初期コミット

```bash
cd "$PROJECT_DIR"
git init  # ボイラーテンプレートが git init 済みでない場合
git add -A
git commit -m "feat: プロジェクト初期化（ボイラーテンプレート + AIテンプレート適用）"
```

### 4.2 完了メッセージ

以下を表示する:

```
✅ プロジェクトの初期化が完了しました！

📁 プロジェクト: {PROJECT_DIR}
🛠 技術スタック: {選定した技術スタック}
📝 要件定義書: doc/input/rdd.md

🚀 次のステップ:
1. 新しいプロジェクトで Claude Code を起動してください:
   cd {PROJECT_DIR} && claude

2. /session-start でセッションを開始してください

3. /task-list でタスクを計画してください
```

### 4.3 テンプレートソースの永続化確認

Phase 0 で新たにテンプレートパスを検出/指定した場合:

```
💡 ai-template のパスを保存しますか？
   保存先: ~/.claude/ai-template-path
   次回から自動検出されます。
```

---

## 出力
- 新規プロジェクトディレクトリ（ボイラーテンプレート + AIテンプレート適用済み）
- `doc/input/rdd.md`（壁打ちの成果が反映済み）
- 初期コミット

---

## 品質チェックリスト
- [ ] rdd.md の「AI用事実ブロック」が埋まっている（技術スタック/ターゲット環境/制約）
- [ ] .claude/skills/ がコピーされ、スキル一覧で認識される
- [ ] CLAUDE.md がプロジェクトルートに存在する
- [ ] .gitignore にセキュリティ関連（.env等）が含まれている
- [ ] ボイラーテンプレートの依存パッケージがインストール済み
- [ ] 初期コミットが作成されている

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {短く理由を記載}

---

## トラブルシューティング

### テンプレートソースが見つからない
```bash
# 手動でパスを設定
echo "/path/to/ai-template" > ~/.claude/ai-template-path
```

### ボイラーテンプレートのCLIが対話式で自動実行できない
- ユーザーに別ターミナルでの手動実行を案内する
- 完了後にこのスキルの Phase 3 から再開する

### 既存プロジェクトにAIテンプレートだけ適用したい
- Phase 2 をスキップして、Phase 0 → Phase 1 → Phase 3 → Phase 4 の順で実行する
- 「既存プロジェクトにテンプレートを適用したい」と伝えればAIが判断する
