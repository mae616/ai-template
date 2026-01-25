# ai-template

Claude Code / Cursor 向けの開発プロンプトテンプレート。

「AIに何をどう伝えるか」を構造化し、人間とAIが協調して開発を進めるための仕組みを提供します。

## 特徴

- **スキルベースの作業フロー**: タスク管理、バグ対応、デザイン連携などを `/command` 形式で実行
- **判断軸の明文化**: CLAUDE.md とスキル定義で、AIの思考・判断基準を共有
- **差分ベースの反復**: 小さな変更を積み重ねる前提の設計（TDD・アジャイル寄り）

参考: [Cole Medin氏 context-engineering-intro](https://github.com/coleam00/context-engineering-intro)

## 前提条件

以下が利用可能な状態であること（インストール手順は各公式を参照）:

| 必須/任意 | ツール | 用途 | 確認方法 | 公式 |
|-----------|--------|------|----------|------|
| **必須** | Claude Code | コア | `claude --version` | [GitHub](https://github.com/anthropics/claude-code) |
| **必須** | GitHub CLI | task/bug管理 | `gh auth status` | [公式](https://cli.github.com/) |
| 任意 | Agent Browser | UI確認/デバッグ | `agent-browser --version` | [GitHub](https://github.com/vercel-labs/agent-browser) |
| 任意 | Figma MCP | /design-ssot | `/mcp` で確認 | [公式ガイド](https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server) |
| 任意 | mise | ツール管理 | `mise --version` | [公式](https://mise.jdx.dev/) |
| 任意 | Cursor | IDE | - | [公式](https://cursor.com/) |

### 公式プラグイン/スキルの設定

各ツールに公式プラグインやスキルがある場合は、それを導入することで連携が強化されます。

```bash
# Agent Browser（Vercel）: ブラウザ自動化でUI確認・デバッグを自律実行
npm install -g agent-browser && agent-browser install

# Figma: 公式プラグイン（MCP + Agent Skills）
claude plugin install figma@claude-plugins-official
```

※ Figma以外のデザインツール（[Pencil](https://www.pencil.dev/) など）は公式MCP/Skillsが未提供の場合があります。その場合も判断軸スキル（ui-designer, frontend-implementation, creative-coder 等）は利用可能です。

## 使い方

**人間が判断し、AIが実行する**という分担で開発を進めます。

- 人間: コンテキスト提供、方針決定、レビュー
- AI: 調査、実装、ドキュメント生成

「丸投げ」ではなく「協調」が前提。速度より再現性と確実性を重視しています。

### セットアップ

このリポジトリをローカル環境に `git clone` してください。
※ `~/` に `clone` した例でこの先のコマンドを記述します。

#### プロジェクトへの適用
このテンプレートを各開発リポジトリへ反映するために、ブートストラップスクリプトを用意しています。

1) `ai-template` を任意の場所に `git clone`
2) 反映したい開発リポジトリの絶対パスを指定して実行

例（まずはdry-run推奨）:
```bash
cd /path/to/ai-template
scripts/apply_template.sh --target /abs/path/to/your-project --safe --dry-run
scripts/apply_template.sh --target /abs/path/to/your-project --safe
```

補足:
- 上書き前に `your-project/.ai-template-backup/<timestamp>/` へバックアップします（`--no-backup` で無効化可能）
- `--safe`（デフォルト）は既存ファイルを上書きしません。テンプレ側の更新を反映したい場合は `--force`、同期して削除も伴う場合は `--sync` を使用します。
- [doc/input/rdd.md](doc/input/rdd.md) は原則 **プロジェクト固有** です。テンプレ更新で上書きしたい場合のみ `--overwrite-rdd` を明示してください。

#### グローバル適用（~/.claude への反映）
スキルや設定をグローバル（全プロジェクト共通）に適用する場合:

```bash
cd /path/to/ai-template

# dry-run で確認
scripts/apply_global.sh --dry-run

# 実行（判断軸スキルのみ）
scripts/apply_global.sh

# 手順系スキルも含めて適用
scripts/apply_global.sh --all-skills
```

詳細な運用方法は [doc/guide/ai_template_operation.md](doc/guide/ai_template_operation.md) を参照してください。
skills一覧（索引）は [doc/guide/skills_catalog.md](doc/guide/skills_catalog.md) を参照してください。
コマンド一覧（索引）は [doc/guide/commands_catalog.md](doc/guide/commands_catalog.md) を参照してください。
ドキュメント全体の入口は [doc/index.md](doc/index.md) です。

#### 開発プロジェクトの作成
ボイラーテンプレートなどでReactなどの開発プロジェクトを作成してください。
その後、`scripts/apply_template.sh` でテンプレートを反映してください。

#### 実行環境について

本テンプレートは **Claude Codeをホスト環境で運用することを想定** しています。
コンテナ化（DevContainer等）での運用は各プロジェクトの判断にお任せします。

## Gitブランチ運用

このテンプレートでは **3層ブランチ構造** を推奨しています。

```
main
├── sprint/*          ← スプリント単位（CI通過後にmainへマージ）
│   ├── task/*        ← タスク単位（AI実装、動作不要）
│   └── feature_fix/* ← スプリント統合後のバグ修正
└── hotfix/*          ← 本番緊急修正
```

| ブランチ | 目的 | CI要件 |
|---------|------|--------|
| `task/*` | AI実装（1タスク単位） | Lint/TypeCheckのみ |
| `feature_fix/*` | スプリント統合後バグ修正 | Lint/TypeCheck |
| `sprint/*` | スプリント全体 | フルビルド/テスト |
| `hotfix/*` | 本番緊急修正 | フルビルド/テスト |

詳細は [doc/guide/git_workflow.md](doc/guide/git_workflow.md) を参照してください。

## Claude Code コマンドの使い方

このリポジトリでは、**AIと人間が協調して安全に実装へ落とし込むためのコマンド**を提供しています。
目的は **AIによるブラックボックス化を避けつつ、人間と対話しながら再現性のある開発** を進めることです。



### 1. カスタム指示を読み込む

通常は自動で読み込まれますが、最初に以下を実行することを推奨します。

```bash
/setup
```
- このリポジトリを使用する場合、各コマンド実行時に `/clear` → `/setup` が走ることを前提としています。

### 補助: リポジトリ案内・壁打ち（任意）

- **[/repo-tour](.claude/skills/repo-tour/SKILL.md)**: 初見向けに「どこに何があるか」を短時間で案内します
  - **入力**: 任意（例: `全体`, `AI運用`, `design`, `commands`, `skills`）
  - **出力**: 全体像 / コアファイル / よく触る場所 / 次の一手
- **[/pair](.claude/skills/pair/SKILL.md)**: 企画/設計/実装/デザインの壁打ちを、短い反復で進めます
  - **入力**: `plan` | `design` | `arch` | `dev`（必須）＋相談内容（任意）
  - **出力**: 短問（1〜3）→選択肢（2〜3）→推奨→次の一手

使用例:

```bash
/repo-tour design
/pair design 設定画面の情報設計を壁打ちしたい
```


### 2. デザイン連携フロー（Figma MCP → 実装/ドキュメント）

#### 前提（SSOT）
- 技術スタックは [doc/input/rdd.md](doc/input/rdd.md) をSSOTとして扱います（design系コマンドもこれに従う）
- SSOT JSONの契約は [doc/input/design/ssot_schema.md](doc/input/design/ssot_schema.md) を参照します

#### 最短ルート（おすすめ）：SSOT → 静的UI骨格 → コンポーネント分割 → 実装へ結合
HTMLは**必須ではありません**（必要なときだけオプションで生成します）。

##### ルートA: 会話起点（まずは叩き台を作る）
1. **[/design-mock](.claude/skills/design-mock/SKILL.md)**（会話から叩き台を作成）
    - **入力**: ユーザーとの会話（画面/要素/雰囲気/制約）
    - **出力**:
        - `doc/input/design/design-tokens.json`
        - `doc/input/design/components.json`
        - `doc/input/design/design_context.json`
        - `doc/input/design/copy.json`
        - `doc/input/design/assets/assets.json`
        - `doc/input/design/html/mock.html`（目で見て調整するための静的HTML）
    - **反復（推奨）**:
        - `mock.html` を手で調整したら、**差分（diff）または変更点の箇条書きを会話で共有**する（状況で使い分けOK）
        - その内容を元に **`/design-mock` を再実行して、HTMLとSSOT（JSON）を同時に更新**する（HTMLだけ更新してSSOTを放置しない）
2. **[/design-ui](.claude/skills/design-ui/SKILL.md)**（SSOT JSON → 静的UI骨格）
    - **入力**: 上記SSOT JSON
    - **出力**: （技術スタック準拠の）静的UI骨格（見た目のみ）
3. **[/design-components](.claude/skills/design-components/SKILL.md)**（静的UI骨格 → コンポーネント/レイアウト抽出）
    - **入力**: 静的UI骨格（見た目のみ。ロジック禁止）
    - **出力**: スタック別の標準配置に合わせて分割
4. **[/design-assemble](.claude/skills/design-assemble/SKILL.md)**（SSOT variants → 型付きProps/属性へマッピングして結合）
    - **入力**: `doc/input/design/components.json`
    - **出力**: 再利用可能なUIコンポーネント（技術スタック準拠）
    - **ゲート**: Story/テスト/Lint がすべて緑（異なるスタック指定時はADR-lite承認）

##### ルートB: Figma起点（Dev Mode → SSOT）
1. **[/design-ssot](.claude/skills/design-ssot/SKILL.md)**（Figma MCPからSSOT JSONを確立）
    - **入力**: Figma（Dev Mode）上の対象（ページ/フレーム等）
    - **出力**:
        - `doc/input/design/design-tokens.json`
        - `doc/input/design/components.json`
        - `doc/input/design/design_context.json`
        - `doc/input/design/copy.json`
        - `doc/input/design/assets/assets.json`
    - **前提（重要）**:
        - Figma MCP（Dev Mode）が利用可能であること（未設定だと `/design-ssot` は動きません）
        - 迷ったら `/design-ssot` の「事前チェック（必須）：Figma MCPが使える状態か」を参照
        - Figma MCPは `claude mcp add --transport http figma "<FIGMA_MCP_URL>"` などで **手動登録が必要**（詳細は `/design-ssot` の「Figma MCPの登録」）
2. **[/design-ui](.claude/skills/design-ui/SKILL.md)**（SSOT JSON → 静的UI骨格）
3. **[/design-components](.claude/skills/design-components/SKILL.md)**（静的UI骨格 → コンポーネント/レイアウト抽出）
4. **[/design-assemble](.claude/skills/design-assemble/SKILL.md)**（components.json → 各技術スタック用UIへ結合）

#### オプション：ドキュメント/共有用に静的HTMLが欲しい場合
- **[/design-html](.claude/skills/design-html/SKILL.md)**（SSOT JSON → 静的HTMLを生成して `doc/input/design/html/` に保存。Figma起点など、SSOTだけ先にある場合に便利）
- **[/design-split](.claude/skills/design-split/SKILL.md)**（1枚ペラHTML → ページ単位へ分割。`/design-mock` で `mock.html` を出した場合に有効）

#### 実行例（会話ルート：最短）
```bash
/design-mock
/design-ui
/design-components src
/design-assemble vue
```

#### 実行例（Figmaルート：最短）
```bash
/design-ssot HomePage=https://...
/design-ui
/design-components src
/design-assemble vue
```

### 3. AIタスクシステム（GitHub Issue/Milestone + 組み込みTask連携）

タスク管理は **GitHub Issues + Milestones** と **Claude Code組み込みTask** を連携して行います。

- **GitHub Issue/Milestone**: 永続化、チーム共有、履歴管理
- **組み込みTask**: セッション内の並行実行、依存管理（blocks/blockedBy）

#### フロー概要

```
/task-list → /task-detail → /task-run
```

1. **Sprint計画（/task-list）**
```bash
/task-list doc/input/rdd.md
```
- Sprint = GitHub Milestone として作成
- タスク = GitHub Issue（ラベル: `task`）+ 組み込みTask として作成
- `metadata.issueNumber` で両者を紐づけ

2. **Issue詳細化（/task-detail）**
```bash
/task-detail sprint-1
```
- 指定Milestone配下のIssueに実装詳細を追記
- 依存関係（blocks/blockedBy）をIssue本文と組み込みTaskの両方に設定
- `ready-for-dev` ラベルを付与

3. **Issue実行（/task-run）**
```bash
/task-run #123
```
- 依存解決済みのIssueを選択して実装
- 進捗は組み込みTaskとIssueコメントの両方に同期
- 完了時: 組み込みTask → `completed`、Issue → `close`

#### スクラム的サイクル

```
1. 要件定義やスプリント計画の作成
→ 2. /task-list で GitHub Issue + Milestone + 組み込みTask 生成
→ 3. /task-detail で Sprint1 の Issue 詳細化 + 依存関係設定
→ 4. /task-run で Sprint1 の Issue 実行（並行・依存管理）
→ 5. Sprint1 完了 → main へマージ
→ 6. 次のSprintへ
```

### 4. トラブルシューティングシステム（GitHub Issue → PR連携）

バグ対応は **GitHub Issue（調査・議論）→ PR（修正）** で行います。

#### フロー概要

1. **バグ起票（bug-new）**
```bash
/bug-new podmanが起動しない
```
- GitHub Issue（ラベル: `bug`）を作成
- 問題の概要、再現手順、仮説を記録

2. **調査（bug-investigate）**
```bash
/bug-investigate #123
```
- Issue番号を指定して調査を実施
- 調査結果はIssueコメントに追記

3. **裏付け（bug-propose）**
```bash
/bug-propose #123
```
- 修正案をIssueコメントに追記
- 環境構築・既存バグには有効
- アプリのロジックバグの場合はスキップ、または新規タスク化推奨

4. **修正実行（bug-fix）**
```bash
/bug-fix #123
```
- ブランチを作成してPRを作成
- `Fixes #123` でIssueに紐づけ
- マージ時にIssueが自動close

### 5. マニュアルシステム

#### フロー概要

1. **ソースコード生成**
- タスクシステムやバグ改修システムでソースを生成

2. **マニュアル生成（manual-gen）**
```bash
/manual-gen supabaseの設定手順書
```
- `doc/generated/manual/` に手順書が生成される

3. **マニュアルガイド（manual-guide）**
```bash
/manual-guide doc/generated/manual/手順書名.md
```
- 生成された手順書をステップごとに案内

### 6. ドキュメント生成（/docs-reverse）

このプロジェクトは、**SSOT（人間が維持する設計情報）**と、**AIが生成して更新するドキュメント**を分離します。

- **SSOT（手編集・入力）**: `doc/input/`
  - [doc/input/rdd.md](doc/input/rdd.md)
  - [doc/input/architecture.md](doc/input/architecture.md)
  - [doc/input/design/](doc/input/design/)（`design-tokens.json` / `components.json` / `design_context.json` など）
- **AI生成（出力・上書きOK）**: `doc/generated/`
  - `doc/generated/reverse/`（`/docs-reverse` の出力先）
  - `doc/generated/manual/`（`/manual-gen` の出力先）

#### 使用例

```bash
/docs-reverse
```

## 📁 プロジェクト構成

```
ai-template/
├── .claude/                   # Claude Code設定
│   ├── skills/                # スキル（判断軸 + 手順系）⭐
│   └── settings.local.json    # AIのコマンド権限
├── doc/                       # ドキュメント
│   ├── index.md               # 総合入口
│   ├── input/                 # 【人間が書く】SSOT
│   │   ├── rdd.md             # 要件定義
│   │   ├── architecture.md    # アーキテクチャ
│   │   └── design/            # デザインSSOT
│   ├── guide/                 # 【テンプレ提供】運用ガイド
│   │   ├── git_workflow.md    # Gitブランチ運用
│   │   ├── commands_catalog.md
│   │   ├── skills_catalog.md
│   │   └── ai_guidelines.md
│   ├── generated/             # 【AI生成】上書きOK
│   │   ├── manual/            # /manual-gen 出力先
│   │   └── reverse/           # /docs-reverse 出力先
│   └── devlog/                # AI作業ログ（任意）
├── scripts/                   # スクリプト
│   ├── apply_template.sh      # プロジェクトへの適用
│   └── apply_global.sh        # ~/.claude への適用
├── .mise.toml                 # ツール管理設定
├── CLAUDE.md                  # Claude Code設定
├── AGENTS.md                  # エージェント指示（Cursor推奨）
├── CONTRIBUTING.md            # コントリビューションガイド
├── CODE_OF_CONDUCT.md         # 行動規範
├── LICENSE                    # MITライセンス
└── README.md                  # このファイル
```

### ⭐ このテンプレートの本質
- **`.claude/skills/`** → 実際の「作業フローを動かすスキル群」
- **[CLAUDE.md](CLAUDE.md) / [doc/input/rdd.md](doc/input/rdd.md) / [.claude/skills/](.claude/skills/) / [doc/guide/ai_guidelines.md](doc/guide/ai_guidelines.md)** → 判断軸（SSOT/運用）

この2つが中核であり、他の構成要素はそれを支える仕組みになっています。


## 🤝 コントリビューション

Feedback only OSS


このプロジェクトへの貢献を歓迎します！

[CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

## 📋 運営体制

**本リポジトリは個人メンテナンス（ボランティア）です。**

### 対応スケジュール
- **返信**: 週1回を目安にまとめて行います

### メンテナンス方針
- 個人の時間の範囲内で対応
- コミュニティの貢献を重視
- 段階的な機能拡張
- 品質を重視した開発

### サポートレベル
- **高**: 基本的な機能とドキュメント
- **中**: バグ修正とセキュリティ対応
- **低**: 新機能追加（コントリビューション歓迎）

## 📚 参考資料

- [MCP Protocol](https://modelcontextprotocol.io/)
- [Figma MCPカタログ（公式）](https://www.figma.com/ja-jp/mcp-catalog/)

## 📄 ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

### ライセンスの概要

- **商用利用**: 可能
- **改変**: 可能
- **配布**: 可能
- **個人利用**: 可能
- **責任**: 作者は一切の責任を負いません


## 🙏 謝辞

このプロジェクトは以下のプロジェクトの恩恵を受けています：

- [Claude Code](https://github.com/anthropics/claude-code) - コード支援AI（CLI/拡張）
- [Cursor IDE](https://cursor.com/) - AI統合開発環境
- [Figma MCPサーバー（公式ガイド）](https://help.figma.com/hc/ja/articles/32132100833559-Figma-MCP%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%81%AE%E3%82%AC%E3%82%A4%E3%83%89) - デザイン情報連携（Dev Mode）
- [mise](https://mise.jdx.dev/) - ツール管理

## 📞 サポート

### 問題の報告

- **GitHub Issues**




⭐ このプロジェクトが役に立ったら、スターを付けてください！
