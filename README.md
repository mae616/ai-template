# Project AI Prompt Template

アプリケーション開発プロジェクト用の汎用AIテンプレートです。
Claude Code, Cursor などのコード支援AIによるアプリ開発のプロンプトテンプレートを提供します。


## 🚀 AIプロンプトテンプレートの特徴
このプロジェクトは、[Cole Medin氏によるcontext-engineering-intro](https://github.com/coleam00/context-engineering-intro)をベースとして参考にしました。


コンテキスト駆動開発(アジャイル仕様開発)用テンプレート。
アプリやAPIの仕様ではなく、AIの思考プロセスそのものを仕様化して扱うためのプロンプト群です。
小さな反復（diff・ストップポイント）を前提とし、アジャイル的に改善しながら開発を進める設計を支援します。



このプロジェクトは少し変わっていて、平たく言うと、私(mae616)のエンジニアリングする際の思考や手順をAIで再現したものです。

## 🚀 使用AI支援開発環境
- [Claude Code](https://github.com/anthropics/claude-code)
- [Serena AI Coding Agent](https://github.com/oraios/serena)
- [Figma MCPサーバー](https://help.figma.com/hc/ja/articles/32132100833559-Figma-MCP%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%81%AE%E3%82%AC%E3%82%A4%E3%83%89) 
- [Cursor](https://cursor.com/)

## 🛠️ 開発環境

### 基本環境
- **DevContainer**: Podman, Ubuntu 22.04 LTS
- **Node.js**: LTS + pnpm
- **AI支援**: Claude Code + Serena AI + Cursor
- **ツール管理**: mise

### ポート設定

- **3000**: 開発サーバー用
- **5173**: Vite開発サーバー用
- **8000**: Serena MCPサーバー用
- **8888**: ポートフォワード用（用途はプロジェクト次第）

## 🌟 対応技術スタック

### 現在サポート済み
- **Node.js**: LTS + pnpm (パッケージ管理)

## 使い方

このプロジェクトは、**AIがすべてを自動で行ってくれるわけではありません**。  
利用者であるあなたは **管理者（ディレクター／マネージャー／指導員の立場）** として、私(mae616)のAIクローンが行う作業の方向性を決め、指示を出す役割を担います。

### あなたの役割
- 要件や修正内容などの **コンテキストを提供すること**  
- タスクやバグ改修の進め方について **判断と指示を行うこと**  

### 主なタスク
- タスクリストを渡して作業を依頼する  
- バグ改修（トラブルシューティング）の起票を指示する  
- 複数段階のバグ改修で行き詰まった場合、新しいバグとして扱うかを判断する  
- バグ調査の結果を受け、新規タスク化するかを判断する  
- 作業が誤った方向に進んでいる場合、方向性を修正したり、中断を指示する  




このように、**AIは実行役、あなたは監督役**という関係で開発が進みます。  
「AIに丸投げ」ではなく、「人間の判断を織り込みながら安全に進める」ことが前提です。

※ このプロジェクトは、AIの応答が遅くても、トークンを多く消費しても、**確実で再現性のある作業**を行うことを目指しています。

### 環境セットアップ

このリポジトリをローカル環境に `git clone` してください。
※ `~/` に `clone` した例でこの先のコマンドを記述します。

#### shellコマンドの設定
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
- [doc/rdd.md](doc/rdd.md) と `ai-task/` は原則 **プロジェクト固有** です。テンプレ更新で上書きしたい場合のみ `--overwrite-rdd` / `--overwrite-ai-task` を明示してください。

詳細な運用方法は [doc/manual/ai_template_operation.md](doc/manual/ai_template_operation.md) を参照してください。
skills一覧（索引）は [doc/manual/skills_catalog.md](doc/manual/skills_catalog.md) を参照してください。
コマンド一覧（索引）は [doc/manual/commands_catalog.md](doc/manual/commands_catalog.md) を参照してください。
ドキュメント全体の入口は [doc/index.md](doc/index.md) です。

#### 開発プロジェクトの作成
ボイラーテンプレートなどでReactなどの開発プロジェクトを作成してください。
その後、`scripts/apply_template.sh` でテンプレートを反映してください。

#### DevContainerの起動
開発プロジェクトをCursor IDEで開き、左下にメッセージが表示されたら、DevContainerの起動ボタンを押してください。

注意: DevContainerは利便性のため **ホスト側の設定ディレクトリ（例: `~/.anthropic` / `~/.claude` / `~/.cursor`）をコンテナへマウント**します。不要な場合は任意で外せます（詳細は [.devcontainer/README.md](.devcontainer/README.md) を参照）。

#### 基本的なセットアップ
```bash
# 環境の確認
node --version
pnpm --version

# 依存関係のインストール
pnpm install
```

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

- **[/repo-tour](.claude/commands/repo-tour.md)**: 初見向けに「どこに何があるか」を短時間で案内します
  - **入力**: 任意（例: `全体`, `AI運用`, `design`, `commands`, `skills`）
  - **出力**: 全体像 / コアファイル / よく触る場所 / 次の一手
- **[/pair](.claude/commands/pair.md)**: 企画/設計/実装/デザインの壁打ちを、短い反復で進めます
  - **入力**: `plan` | `design` | `arch` | `dev`（必須）＋相談内容（任意）
  - **出力**: 短問（1〜3）→選択肢（2〜3）→推奨→次の一手

使用例:

```bash
/repo-tour design
/pair design 設定画面の情報設計を壁打ちしたい
```


### 2. デザイン連携フロー（Figma MCP → 実装/ドキュメント）

#### 前提（SSOT）
- 技術スタックは [doc/rdd.md](doc/rdd.md) をSSOTとして扱います（design系コマンドもこれに従う）
- SSOT JSONの契約は [doc/design/ssot_schema.md](doc/design/ssot_schema.md) を参照します

#### 最短ルート（おすすめ）：SSOT → 静的UI骨格 → コンポーネント分割 → 実装へ結合
HTMLは**必須ではありません**（必要なときだけオプションで生成します）。

##### ルートA: 会話起点（まずは叩き台を作る）
1. **[/design-mock](.claude/commands/design-mock.md)**（会話から叩き台を作成）
    - **入力**: ユーザーとの会話（画面/要素/雰囲気/制約）
    - **出力**:
        - `doc/design/design-tokens.json`
        - `doc/design/components.json`
        - `doc/design/design_context.json`
        - `doc/design/html/mock.html`（目で見て調整するための静的HTML）
    - **反復（推奨）**:
        - `mock.html` を手で調整したら、**差分（diff）または変更点の箇条書きを会話で共有**する（状況で使い分けOK）
        - その内容を元に **`/design-mock` を再実行して、HTMLとSSOT（JSON）を同時に更新**する（HTMLだけ更新してSSOTを放置しない）
2. **[/design-ui](.claude/commands/design-ui.md)**（SSOT JSON → 静的UI骨格）
    - **入力**: 上記SSOT JSON
    - **出力**: （技術スタック準拠の）静的UI骨格（見た目のみ）
3. **[/design-components](.claude/commands/design-components.md)**（静的UI骨格 → コンポーネント/レイアウト抽出）
    - **入力**: 静的UI骨格（見た目のみ。ロジック禁止）
    - **出力**: スタック別の標準配置に合わせて分割
4. **[/design-assemble](.claude/commands/design-assemble.md)**（SSOT variants → 型付きProps/属性へマッピングして結合）
    - **入力**: `doc/design/components.json`
    - **出力**: 再利用可能なUIコンポーネント（技術スタック準拠）
    - **ゲート**: Story/テスト/Lint がすべて緑（異なるスタック指定時はADR-lite承認）

##### ルートB: Figma起点（Dev Mode → SSOT）
1. **[/design-ssot](.claude/commands/design-ssot.md)**（Figma MCPからSSOT JSONを確立）
    - **入力**: Figma（Dev Mode）上の対象（ページ/フレーム等）
    - **出力**:
        - `doc/design/design-tokens.json`
        - `doc/design/components.json`
        - `doc/design/design_context.json`
2. **[/design-ui](.claude/commands/design-ui.md)**（SSOT JSON → 静的UI骨格）
3. **[/design-components](.claude/commands/design-components.md)**（静的UI骨格 → コンポーネント/レイアウト抽出）
4. **[/design-assemble](.claude/commands/design-assemble.md)**（components.json → 各技術スタック用UIへ結合）

#### オプション：ドキュメント/共有用に静的HTMLが欲しい場合
- **[/design-html](.claude/commands/design-html.md)**（SSOT JSON → 静的HTMLを生成して `doc/design/html/` に保存。Figma起点など、SSOTだけ先にある場合に便利）
- **[/design-split](.claude/commands/design-split.md)**（1枚ペラHTML → ページ単位へ分割。`/design-mock` で `mock.html` を出した場合に有効）

#### 実行例（会話ルート：最短）
```bash
/design-mock
/design-ui
/design-components src
/design-assemble vue
```

#### 実行例（Figmaルート：最短）
```bash
/design-ssot HomePage
/design-ui
/design-components src
/design-assemble vue
```

### 3. AIタスクシステム

#### フロー概要

1. **要件定義作成**  
- 新規: [doc/rdd.md](doc/rdd.md) に記述  
- 改修: [doc/rdd.md](doc/rdd.md) に追記（差分で更新）  

2. **TASK-LIST生成**  
```bash
/task-list doc/rdd.md
```
- タスク一覧、依存関係、優先度、スプリント計画が生成される  

3. **TASK生成**  
```bash
/task-gen ai-task/task/機能名/TASK-LIST-機能名.md sprint1
```
- Sprintごとの詳細タスクを生成  

4. **TASK実行**  
```bash
/task-run ai-task/task/機能名/TASK_{sprint}_{feature_name}_{short}.md
```
- AIが段階的に実装・検証を進める  



#### スクラム的サイクル

```
1.	要件定義やスプリント計画の作成
→ 2. TASK-LIST生成
→ 3. Sprint1のTASK生成
→ 4. Sprint1のTASK実行（ユーザー確認）
→ 5. Sprint2のTASK生成
→ 6. Sprint2のTASK実行（ユーザー確認）
→ …
```

### 4. トラブルシューティングシステム

#### フロー概要

1. **バグ起票（bug-new）**  
```bash
/bug-new podmanが起動しない
```
- [ai-task/bug/バグファイル名.md](ai-task/bug/README.md) を生成（実体は `ai-task/bug/` 配下に作成）  

2. **調査（bug-investigate）**  
```bash
/bug-investigate ai-task/bug/バグファイル名.md
```
- 現状調査と仮説を追記  

3. **裏付け（bug-propose）**  
```bash
/bug-propose ai-task/bug/バグファイル名.md
```
- Web検索で修正案を確認  
- ⚠️ 環境構築・既存バグには有効  
- ⚠️ アプリのロジックバグの場合はスキップ、または新規タスク化推奨  

4. **修正実行（bug-fix）**  
```bash
/bug-fix ai-task/bug/バグファイル名.md
```
- 修正を実行  
- 新たなエラーが出た場合は再度起票し、フローを繰り返す  

### 5. マニュアルシステム

#### フロー概要

1. **ソースコード生成**  
- タスクシステムやバグ改修システムでソースを生成  

2. **マニュアル生成（manual-gen）**  
```bash
/manual-gen supabaseの設定手順書
```
- `doc/manual/手順書名.md` が生成される（例：`doc/manual/` 配下。索引は [doc/manual/](doc/manual/)）  

3. **マニュアルガイド（manual-guide）**  
```bash
/manual-guide doc/manual/手順書名.md
```
- 生成された手順書をステップごとに案内  

### 6. ドキュメント生成（/docs-reverse）

このプロジェクトは、**SSOT（人間が維持する設計情報）**と、**AIが生成して更新するドキュメント**を分離します。

- **SSOT（手編集・入力）**
  - [doc/rdd.md](doc/rdd.md)
  - [doc/Architecture.md](doc/Architecture.md)
  - [doc/design/](doc/design/)（`design-tokens.json` / `components.json` / `design_context.json` など）
- **AI生成（出力・上書きOK）**
  - `doc/_generated/`（`/docs-reverse` の出力先）

#### 使用例

```bash
/docs-reverse
```

## 📁 プロジェクト構成

```
ai-template/
├── .claude/                   # Claude Code設定
│   ├── commands/              # Claude Codeのコマンド⭐
│   └── settings.local.json    # AIのコマンド権限
├── .devcontainer/             # DevContainer設定
├── ai-task/                   # AIタスク管理
│   ├── task/                  # 開発タスク（/task-* の出力先）
│   └── bug/                   # バグ対応ログ（/bug-* の出力先）
├── doc/                       # ドキュメント
│   ├── _generated/            # AI生成（/docs-reverse の出力先。上書きOK）
│   ├── index.md               # ドキュメントの入口（読む順番）
│   ├── manual/                # マニュアル
│   └── devlog/                # AI作業ログ（任意）
├── .mise.toml                 # ツール管理設定
├── CLAUDE.md                  # Claude Code設定
├── AGENTS.md                  # エージェント指示（Cursor推奨）
├── CONTRIBUTING.md            # コントリビューションガイド
├── CODE_OF_CONDUCT.md         # 行動規範
├── LICENSE                    # MITライセンス
└── README.md                  # このファイル
```

### ⭐ このテンプレートの本質
- **`.claude/commands/`** → 実際の「作業フローを動かすコマンド群」  
 - **[CLAUDE.md](CLAUDE.md) / [doc/rdd.md](doc/rdd.md) / [.claude/skills/](.claude/skills/) / [doc/ai_guidelines.md](doc/ai_guidelines.md)** → 判断軸（SSOT/運用）

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

- [Claude Code](https://github.com/anthropics/claude-code)
- [Serena GitHub](https://github.com/oraios/serena)
- [Serena Documentation](https://github.com/oraios/serena#readme)
- [MCP Protocol](https://modelcontextprotocol.io/)
- [Figma MCPサーバーのガイド（公式）](https://help.figma.com/hc/ja/articles/32132100833559-Figma-MCP%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%81%AE%E3%82%AC%E3%82%A4%E3%83%89)
- [Figma MCPカタログ（公式）](https://www.figma.com/ja-jp/mcp-catalog/)
- [Cursor IDE](https://cursor.com/)
- [mise](https://mise.jdx.dev/)
- [uv](https://github.com/astral-sh/uv)
- [Podman](https://podman.io/)
- [DevContainer](https://containers.dev/)

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
- [Serena AI](https://github.com/oraios/serena) - AI支援開発エージェント
- [Cursor IDE](https://cursor.com/) - AI統合開発環境
- [Figma MCPサーバー（公式ガイド）](https://help.figma.com/hc/ja/articles/32132100833559-Figma-MCP%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%81%AE%E3%82%AC%E3%82%A4%E3%83%89) - デザイン情報連携（Dev Mode）
- [DevContainer](https://containers.dev/) - コンテナ化された開発環境
- [Podman](https://podman.io/) - コンテナエンジン
- [mise](https://mise.jdx.dev/) - ツール管理

## 📞 サポート

### 問題の報告

- **GitHub Issues**




⭐ このプロジェクトが役に立ったら、スターを付けてください！
