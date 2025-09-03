# Project AI Prompt Template

アプリケーション開発プロジェクト用の汎用AIテンプレートです。
Claude Code, Cursor などのコード支援AIによるアプリ開発のプロンプトテンプレートを提供します。


## 🚀 AIプロンプトテンプレートの特徴
このプロジェクトは、[Cole Medin氏によるcontext-engineering-intro](https://github.com/coleam00/context-engineering-intro)をベースとして参考にしました。


コンテキスト駆動開発(アジャイル仕様開発)用テンプレート。
アプリやAPIの仕様ではなく、AIの思考プロセスそのものを仕様化して扱うためのプロンプト群です。
小さな反復（diff・ストップポイント）を前提とし、アジャイル的に改善しながら開発を進める設計を支援します。



このプロジェクトは少し変わっていて、平たく言うと、私(mae616)のエンジニアリングする際の思考や手順をAIで完全再現したものです。

## 🚀 使用AI支援開発環境
* Claude Code<br>https://github.com/anthropics/claude-code
* Serena AI Coding Agent<br>https://github.com/oraios/serena
* Cursor<br>https://cursor.com/

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
- **8888**: 8000ポートへのマッピング（追加開発サーバー用）

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
`~/.zshrc`または`~/.bashrc`に以下の関数を追加してください。
```
# ai-template
apply_template() {
    rsync -av \
      --exclude '.git' \
      --exclude '.venv' \
      --exclude 'LICENSE' \
      --exclude 'CODE_OF_CONDUCT.md' \
      --exclude 'CONTRIBUTING.md' \
      --exclude 'SECURITY.md' \
      --exclude 'MAINTAINERS.md' \
      --exclude 'README.md' \
      ~/ai-template/ ./ 
}
```
`source ~/.zshrc`または`source ~/.bashrc` を実行してください。

#### 開発プロジェクトの作成
ボイラーテンプレートなどでReactなどの開発プロジェクトを作成してください。
そのプロジェクト内で `apply_template` を実行してください。

#### DevContainerの起動
開発プロジェクトをCursor IDEで開き、左下にメッセージが表示されたら、DevContainerの起動ボタンを押してください。

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
/read-instructions
```
- `.ai-instructions/core-personality.md` の「## ペルソナ設定 🐱 !!重要!!」は好みに応じて編集してください。
- このリポジトリを使用する場合、各コマンド実行時に `/clear` → `/read-instructions` が走ることを前提としています。


### 2. デザイン連携フロー（Figma MCP → 実装/ドキュメント）

⚠️ **現在制作中（設計も未確定のため実用不可）**

#### フロー概要

1. **design-extract**  
    - Figma MCPから **Design Tokens / Components / Constraints** をJSON化  
    - 出力:  
        - `design/design-tokens.json`  
        - `design/components.json`  
        - `doc/design/design_context.json`  
    - 実装は禁止。まずは **SSOT（Single Source of Truth）** を確立  

2. **design-skeleton**  
    - JSONから **静的UI骨格** を生成（見た目のみ）  
    - RDD準拠の技術スタックを採用（React/Vue/SwiftUIなど）  

3. **design-export-html**  
    - JSONから **静的HTML** を生成し、`doc/design/html/` に保存  
    - ドキュメント配布用に使用  

4. **design-bind**  
    - `components.json` を基に、各スタックに結合するアダプタを生成  
    - 出力: 再利用可能なUIコンポーネント（React/Vue/Svelte/SwiftUI/Flutterなど）  
    - ゲート: Story/テスト/Lint がすべて緑であること  
    - 異なるスタック指定時は **ADR-lite承認必須**  

#### 実行例
```bash
/design-extract HomePage
/design-skeleton
/design-export-html HomePage
/design-bind vue
```

### 3. AIタスクシステム

#### フロー概要

1. **要件定義作成**  
- 新規: `doc/rdd.md` に記述  
- 改修: `ai-task/INITIAL.md` をコピーして記述  

2. **TASK-LIST生成**  
```bash
/generate-task-list ai-task/project-overview.md
```
- タスク一覧、依存関係、優先度、スプリント計画が生成される  

3. **TASK生成**  
```bash
/generate-task ai-task/機能名/task-list-*.md sprint1
```
- Sprintごとの詳細タスクを生成  

4. **TASK実行**  
```bash
/execute-task ai-task/機能名/TASK_{sprint_number}_{feature_name}.md
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

1. **バグ起票（generate-trouble-shooting）**  
```bash
/generate-trouble-shooting podmanが起動しない
```
- `ai-task/trouble-shooting/バグファイル名.md` を生成  

2. **調査（investigate-trouble-shooting）**  
```bash
/investigate-trouble-shooting ai-task/trouble-shooting/バグファイル名.md
```
- 現状調査と仮説を追記  

3. **裏付け（propose-trouble-shooting）**  
```bash
/propose-trouble-shooting ai-task/trouble-shooting/バグファイル名.md
```
- Web検索で修正案を確認  
- ⚠️ 環境構築・既存バグには有効  
- ⚠️ アプリのロジックバグの場合はスキップ、または新規タスク化推奨  

4. **修正実行（execute-fix-trouble-shooting）**  
```bash
/execute-fix-trouble-shooting ai-task/trouble-shooting/バグファイル名.md
```
- 修正を実行  
- 新たなエラーが出た場合は再度起票し、フローを繰り返す  

### 5. マニュアルシステム

#### フロー概要

1. **ソースコード生成**  
- タスクシステムやバグ改修システムでソースを生成  

2. **マニュアル生成（generate-manual）**  
```bash
/generate-manual supabaseの設定手順書
```
- `doc/manual/手順書名.md` が生成される  

3. **マニュアルガイド（guide-manual）**  
```bash
/guide-manual doc/manual/手順書名.md
```
- 生成された手順書をステップごとに案内  

### 6. ドキュメント生成（開発中）

このプロジェクトは、以下の主要ファイル以外のドキュメントを  
**AIによるリバースエンジニアリングで生成**することを想定しています。  

- `doc/rdd.md`  
- `doc/Architecture.md`  
- `doc/design/*`  

#### 使用例
```bash
/reverse-docs
```

## 📁 プロジェクト構成

```
ai-template/
├── .ai-instructions/          # AI指示ファイル⭐
├── .claude/                   # Claude Code設定
│   ├── commands/              # Claude Codeのコマンド⭐
│   └── settings.local.json    # AIのコマンド権限
├── .devcontainer/             # DevContainer設定
├── ai-task/                   # AIタスク管理
│   ├── templates/             # タスクテンプレート
│   └── trouble-shooting/      # 問題解決履歴
├── doc/                       # ドキュメント
│   ├── design_document/       # 設計ドキュメント
│   ├── manual/                # マニュアル
│   ├── pdf/                   # PDFファイル
│   ├── test_case/             # テストケース
│   └── uml/                   # UML図
├── .mise.toml                 # ツール管理設定
├── CLAUDE.md                  # Claude Code設定
├── .cursorrules               # Cursor設定
├── CONTRIBUTING.md            # コントリビューションガイド
├── CODE_OF_CONDUCT.md         # 行動規範
├── LICENSE                    # MITライセンス
└── README.md                  # このファイル
```

### ⭐ このテンプレートの本質
- **`.ai-instructions/`** → AIに与える「思考や行動の設計書」  
- **`.claude/commands/`** → 実際の「作業フローを動かすコマンド群」  

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
- [Cursor IDE](https://cursor.sh/)
- [mise](https://mise.jdx.dev/)
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

- [Serena AI](https://github.com/oraios/serena) - AI支援開発エージェント
- [Cursor IDE](https://cursor.sh/) - AI統合開発環境
- [DevContainer](https://containers.dev/) - コンテナ化された開発環境
- [Podman](https://podman.io/) - コンテナエンジン
- [mise](https://mise.jdx.dev/) - ツール管理

## 📞 サポート

### 問題の報告

- **GitHub Issues**




⭐ このプロジェクトが役に立ったら、スターを付けてください！
