# Project AI Prompt Template

アプリケーション開発プロジェクト用の汎用AIテンプレートです。
Claude Code, Cursor などのコード支援AIによるアプリ開発のプロンプトテンプレートを提供します。


!! このプロジェクトは現在開発中です !!

## 🚀 AIタスクシステムの特徴
このプロジェクトは、[Cole Medin氏によるcontext-engineering-intro](https://github.com/coleam00/context-engineering-intro)をベースとして参考にしました。
コンテキスト・エンジニアリングを活かしつつも、スクラム的なサイクルでTASK-LISTとTASKによりスプリントごとに確認可能な開発のプロンプトを提供します。


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

このリポジトリでは、AIと人間が協調して安全に実装へ落とし込むためのコマンドを用意しています。  
目的は AIによるブラックボックス化を避けつつ、人間と対話しつつ再現性のある開発 を進めることです。


### 1. デザイン連携フロー（Figma MCP → 実装/ドキュメント） (この機能は現在制作中です)

#### フロー概要

1. **design-extract**  
   - Figma MCPから **Design Tokens / Components / Constraints** をJSON化  
   - 出力:  
     - `design/design-tokens.json`  
     - `design/components.json`  
     - `doc/design/design_context.json`  
   - 実装禁止。まずは**SSOT（Single Source of Truth）**を確立するステージ。

2. **design-skeleton**  
   - JSONを参照して **静的UI骨格** を生成  
   - ロジックや状態は持たず、**tokens/variantsに基づく見た目のみ**  
   - RDDの技術スタックを既定に採用（React/Vue/SwiftUIなど）。  
   - ゲート: Storybookやプレビューでデザイン一致を確認。

3. **design-export-html**  
   - JSONから **静的HTML** を生成し、`doc/design/html/` に保存  
   - ドキュメント用の配布形式。外部依存なく閲覧可能。  
   - 主要ブレークポイントでレイアウトが崩れないことを確認。

4. **design-bind**  
   - `components.json` の variants を **props/属性** に落とし込み、  
     RDD準拠の技術スタックに結合するアダプタ層を生成。  
   - 出力は各スタックの再利用可能コンポーネント（React/Vue/Svelte/SwiftUI/Flutterなど）。  
   - ゲート: Story/テスト/Lintすべて緑。  
   - 異なるスタックを指定する場合は **ADR-lite承認必須**。

#### 実行例

1. Figma設計の抽出
`/design-extract HomePage`


2. 骨格生成（既定スタック=React）
`/design-skeleton`


3. ドキュメント用HTMLを生成
`/design-export-html HomePage`


4. スタック結合（例: Vueにバインド）
`/design-bind vue`


### 2. AIタスクシステム

#### フロー概要

**Step 1: RDDやコンテキストの作成**
アプリの新規作成の場合 `doc/` フォルダの配下にrdd.mdで要件定義を記述してください。
改修の場合は `ai-task/` フォルダ配下の `INITIAL.md` をコピーして、要件を記述してください。


**Step 2: TASK-LIST生成（generate-task-list）**
Claude Code で `/generate-task-list` を実行します。
要件定義書の相対パスか `ai-task/` フォルダ配下に記述した要件ファイルを引数に渡してください。

包括的なTASK-LISTが生成されます。

**使用例:**
```bash
# 要件ファイル: ai-task/project-overview.md
# 実行: /generate-task-list ai-task/project-overview.md
```

**生成されるもの:**
- `ai-task/機能名/task-list*.md` - 全体のタスク一覧
- 優先順位と依存関係
- スプリント計画
- 成功基準


**Step 3: TASK生成（generate-task）**
生成されたタスクリストから、スプリント分のタスクの内容のプロンプトを生成します。

**使用例:**
```bash
# タスク概要: ai-task/機能名/task-list-*.md
# 実行: /generate-task ai-task/機能名/task-list-*.md
```

**生成されるもの:**
- `ai-task/機能名/TASK_{sprint_number}_{feature_name}.md` - 詳細な実装TASK
- 必要なコンテキストと調査結果
- 検証手順


**Step 3: TASK実行（execute-task）**
```bash
# TASKファイルが生成されたら
1. execute-taskコマンドでTASKを実行
2. AIが段階的に実装を進める
3. 各段階で検証を実行
4. 完了まで自動的に進む
```

**使用例:**
```bash
# TASKファイル: ai-task/機能名/TASK_{sprint_number}_{feature_name}.md
# 実行: /execute-task ai-task/機能名/TASK_{sprint_number}_{feature_name}.md
```

#### 使用例

#### スクラム的開発サイクル
```
1. スプリント計画 → 2. TASK-LIST生成 → 3. TASK生成 → 4. TASK1実行 → ユーザーがアプリを確認 → 5. TASK2実行 → ユーザーがアプリを確認 → ...
```

### 3. マニュアルシステム


### 4. トラブルシューティングシステム

## 📁 プロジェクト構成

```
ai-template/
├── .ai-instructions/          # AI指示ファイル
├── .claude/                   # Claude Code設定
│   ├── commands/              # AIタスクシステムのコマンド
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

## 🤝 コントリビューション

Feedback only OSS


このプロジェクトへの貢献を歓迎します！

[CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

## 📋 運営体制

**本リポジトリは個人メンテナンス（ボランティア）です。**

### 対応スケジュール
- **返信・レビュー**: 週1回を目安にまとめて行います
- **緊急対応**: お急ぎの方はPRで具体例を添えてください🙏

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

### ライセンステキスト


## 🙏 謝辞

このプロジェクトは以下のプロジェクトの恩恵を受けています：

- [Serena AI](https://github.com/oraios/serena) - AI支援開発エージェント
- [Cursor IDE](https://cursor.sh/) - AI統合開発環境
- [DevContainer](https://containers.dev/) - コンテナ化された開発環境
- [Podman](https://podman.io/) - コンテナエンジン
- [mise](https://mise.jdx.dev/) - ツール管理

## 📞 サポート

### 問題の報告

- **GitHub Issues**:
- **ディスカッション**

---

⭐ このプロジェクトが役に立ったら、スターを付けてください！
