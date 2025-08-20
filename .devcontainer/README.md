# Dev Container 設定

このディレクトリには、AI App開発用のDev Container設定が含まれています。

## 🚀 主な機能

- **Serena AI統合**: Serena AI Coding Agentが利用可能
- **Cursor MCPサーバー**: Cursor IDEとの統合
- **Claude Code統合**: AnthropicのClaude Code拡張機能が利用可能
- **ホスト拡張機能同期**: ホストのVSCode拡張機能がコンテナ内でも利用可能
- **Node.js LTS**: 最新のNode.js環境
- **Python + uv**: 効率的なPython環境管理
- **mise**: 統一されたツール管理
- **開発ツール**: pnpm、その他の開発支援ツール

## 🛠️ 使用方法

### 1. Dev Containerの起動

VSCode/Cursorでこのワークスペースを開き、`Ctrl+Shift+P`（または`Cmd+Shift+P`）でコマンドパレットを開き、以下を実行：

```
Dev Containers: Reopen in Container
```

### 2. 初回起動時の処理

初回起動時は以下の処理が自動実行されます：

- コンテナのビルド
- 必要なパッケージのインストール
- Node.js環境のセットアップ
- Python環境のセットアップ
- ホストのVSCode拡張機能の同期
- Claude Code のインストール
- Serena AI MCPサーバーのセットアップ
- Cursor MCPサーバーのセットアップ

### 3. AI支援開発の利用

コンテナ内で以下のAI支援機能が利用可能になります：

#### Serena AI Coding Agent
- コードの説明・解説
- バグの特定と修正提案
- コードの最適化提案
- テストコードの生成
- プロジェクトオンボーディング

#### Claude Code
- コードの説明・解説
- バグの特定と修正提案
- コードの最適化提案
- テストコードの生成

#### Cursor MCPサーバー
- Cursor IDEとの統合
- リアルタイムAI支援
- MCPプロトコルによる標準的なAIツール統合

### 4. 拡張機能の同期

ホストでインストールしたVSCode拡張機能は、コンテナ内でも自動的に利用可能になります。

## ⚙️ 設定ファイル

### Serena AI MCP設定
- **設定ディレクトリ**: `.serena/`
- **プロジェクト設定**: `.serena/project.yml`
- **メモリ管理**: `.serena/memories/`

### Claude Code MCP設定
- **設定ディレクトリ**: `/root/.claude`
- **MCP設定ファイル**: `/root/.claude/mcp-config.json`
- **環境変数ファイル**: `/root/.claude/.env`

### Cursor MCP設定
- **設定ディレクトリ**: `/root/.cursor`
- **MCP設定ファイル**: `/root/.cursor/mcp-config.json`
- **環境変数ファイル**: `/root/.cursor/.env`

### 環境変数の設定
Serena AIとCursor MCPサーバーはAPIキーなしで動作します。特別な設定は不要です。

```bash
# 環境変数ファイルは自動で作成されます
# 内容: /root/.claude/.env, /root/.cursor/.env
```

## 🔧 セットアップスクリプト

### setup.sh
メインのセットアップスクリプトで、以下の処理を実行します：
- Python環境の確認とuvの設定
- mise環境の初期化とツールインストール
- Node.js環境のセットアップ
- pnpmの設定とメモリ最適化
- Claude Codeのインストール
- Serena AI MCPサーバーのセットアップ
- 開発用エイリアスの設定

### setup-cursor-mcp.sh
Cursor MCPサーバー専用のセットアップスクリプトで、以下の処理を実行します：
- ホストのCursor設定の確認とコピー
- Cursor用MCP設定ファイルの作成
- 環境変数ファイルの作成
- Cursor MCPサーバーの起動

## 🌐 ポート設定

- **3000**: 開発サーバー用
- **5173**: Vite開発サーバー用
- **8000**: Serena MCPサーバー用
- **8001**: 追加開発サーバー用
- **8002**: Cursor MCPサーバー用
- **8888**: Jupyter Notebook用

## 🔍 トラブルシューティング

### 拡張機能が同期されない場合

1. ホストのVSCode拡張機能ディレクトリを確認：
   ```bash
   ls ~/.vscode/extensions
   ```

2. Dev Containerを再構築：
   ```
   Dev Containers: Rebuild Container
   ```

### Serena AIが動作しない場合

1. コンテナ内でSerena AIの状態を確認：
   ```bash
   serena mcp status
   ```

2. プロジェクト設定を確認：
   ```bash
   cat .serena/project.yml
   ```

3. 必要に応じて手動でセットアップ：
   ```bash
   bash .devcontainer/setup.sh
   ```

### Claude Codeが動作しない場合

1. コンテナ内でClaude Code拡張機能がインストールされているか確認
2. 必要に応じて手動でインストール：
   ```
   Extensions: Install Extensions
   ```
   で "Claude Code" を検索してインストール

### Claude Code MCPサーバーが動作しない場合

1. MCPサーバーの状態を確認：
   ```bash
   claude-mcp-status
   ```

2. 環境変数ファイルを確認：
   ```bash
   cat /root/.claude/.env
   ```

3. MCPサーバーを再起動：
   ```bash
   claude-mcp-restart
   ```

4. ログを確認：
   ```bash
   claude-mcp-logs
   ```

### Cursor MCPサーバーが動作しない場合

1. MCPサーバーの状態を確認：
   ```bash
   ps aux | grep cursor
   ```

2. ログを確認：
   ```bash
   cat /tmp/cursor-mcp.log
   ```

3. 手動でセットアップスクリプトを実行：
   ```bash
   bash .devcontainer/setup-cursor-mcp.sh
   ```

### メモリ不足の問題が発生した場合

1. 環境変数を確認：
   ```bash
   echo $NODE_OPTIONS
   echo $pnpm_store_dir
   ```

2. 必要に応じて手動で設定：
   ```bash
   export NODE_OPTIONS="--max-old-space-size=512"
   export pnpm_store_dir="/tmp/.pnpm-store"
   export pnpm_cache_dir="/tmp/.pnpm-cache"
   ```

## 📁 設定ファイル一覧

- `devcontainer.json`: Dev Containerの基本設定
- `Dockerfile`: コンテナイメージの定義
- `docker-compose.yml`: コンテナの起動設定
- `setup.sh`: 初期セットアップスクリプト
- `setup-cursor-mcp.sh`: Cursor MCPサーバーセットアップスクリプト

## ⚠️ 注意事項

- 初回起動時は時間がかかる場合があります
- ホストの拡張機能ディレクトリが存在しない場合は自動で作成されます
- コンテナ内での変更は、ホストのファイルシステムに反映されます
- Serena AIとCursor MCPサーバーはAPIキーなしで動作します
- ホストの設定が自動的にコンテナ内に同期されます
- メモリ使用量を最適化するため、一時ディレクトリを使用しています
- 環境変数は`.bashrc`に追加され、新しいターミナルセッションで有効になります

## 🚀 開発用エイリアス

セットアップ完了後、以下のエイリアスが利用可能になります：

```bash
# Python開発用
alias py='python'
alias pip='uv pip'
alias venv='uv venv'

# プロジェクト管理用
alias dev='pnpm run dev'
alias build='pnpm run build'
alias test='pnpm run test'
alias lint='pnpm run lint'
```
