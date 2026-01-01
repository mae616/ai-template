# Dev Container 設定

このディレクトリには、AI App開発用のDev Container設定が含まれています。

## 🚀 主な機能

- **Serena AI統合**: Serena AI Coding Agentが利用可能
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

補足：
- `.devcontainer/setup.sh` は **冪等**（同じ設定を何度も追記しない）になるようにしています。

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
- **設定ディレクトリ**: `/root/.cursor`（ホストからマウント）
- **エージェント指示**: `AGENTS.md`（リポジトリ直下。Cursor推奨）

## 🔐 セキュリティ注意（ホスト設定のマウントは任意）

このテンプレートは利便性のため、`.devcontainer/devcontainer.json` の `mounts` で **ホスト（ローカル）の設定ディレクトリ**をコンテナへバインドしています。

- **マウント対象例**:
  - `~/.claude` → `/root/.claude`
  - `~/.cursor` → `/root/.cursor`
  - `~/.anthropic` → `/root/.anthropic`

注意:
- **これは任意**です。社内規定/セキュリティ方針により「ホストの設定（場合によっては認証情報を含む）をコンテナへ渡したくない」場合は、`mounts` から該当行を削除（またはコメントアウト）してください。
- **APIキーやトークン等のSecretsはリポジトリへコミットしない**でください（`.env` 管理・Git管理外が前提）。

### 環境変数の設定
Serena AIはAPIキーなしで動作します。特別な設定は不要です。

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
- Figma MCP（Dev Mode）を Claude Code に登録
- 開発用エイリアスの設定

## 🌐 ポート設定

- **3000**: 開発サーバー用
- **5173**: Vite開発サーバー用
- **8000**: Serena MCPサーバー用
- **8001**: 追加開発サーバー用
- **8888**: Jupyter Notebook用

補足（Figma MCP）:
- **Figma Desktop（ホスト側）の Dev Mode MCP** にコンテナ内の Claude Code から接続する場合、`forwardPorts` は原則不要です（用途が「コンテナ→ホスト」接続のため）。
- 接続先は `http://host.docker.internal:3845/mcp` を想定し、`.devcontainer/setup.sh` で `FIGMA_MCP_URL` として扱います（必要なら環境変数で上書き可能）。

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

### Figma MCP が Claude Code に登録されていない（/使えない）場合

前提（ホスト側）:
- Figma Desktop を起動していること（ホスト側で Dev Mode MCP サーバーが立ち上がります）
- Figma Desktop で **Dev Mode MCP** を有効化していること

確認（コンテナ内）:

```bash
claude --version
claude mcp list
```

補足:
- `claude mcp list` が空のままの場合、`postCreateCommand` の `.devcontainer/setup.sh` が途中で失敗している可能性があります（後述の手動実行で切り分けできます）

手動で登録（コンテナ内）:

```bash
FIGMA_MCP_URL="${FIGMA_MCP_URL:-http://host.docker.internal:3845/mcp}"
claude mcp add --transport http figma "${FIGMA_MCP_URL}"
claude mcp list
```

うまくいかないときの切り分け:
- `host.docker.internal` が解決できない環境では、ホストのIPへ置き換えてください（例: `http://<host-ip>:3845/mcp`）
- Podman を使っている場合は `host.containers.internal` が使えることが多いです（例: `http://host.containers.internal:3845/mcp`）
- Figma側のMCPが起動していない/ポートが違う場合は、Figmaの設定を見直してください
  - `curl` が `000` や `Connection refused` の場合は、まず **Figma Desktop が起動しているか**を確認してください（起動していないとホスト側で待受が存在しません）

到達性の確認（コンテナ内）:

```bash
curl -sS -o /dev/null -m 2 -w "%{http_code}\n" http://host.containers.internal:3845/mcp || true
curl -sS -o /dev/null -m 2 -w "%{http_code}\n" http://host.docker.internal:3845/mcp || true
```

Serena MCP も未登録の場合（コンテナ内）:

```bash
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project "$(pwd)"
claude mcp list
```

`setup.sh` を手動実行して切り分け（コンテナ内）:

```bash
bash .devcontainer/setup.sh
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
