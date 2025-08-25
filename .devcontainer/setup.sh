#!/bin/bash
set -e

echo "🚀 Serena AI Coding Agent DevContainer セットアップを開始します..."

# Python環境の確認
echo "📋 Python環境を確認中..."
python --version
pip --version

# uvの確認
echo "📋 uvパッケージマネージャーを確認中..."
uv --version

# mise環境の確認と初期化
echo "📋 mise環境を確認中..."
mise --version
echo "🔧 miseの環境を設定中..."
mise activate

# .mise.tomlに基づいてツールをインストール（メモリ使用量を最適化）
echo "🔧 .mise.tomlに基づいてツールをインストール中..."
if [ -f ".mise.toml" ]; then
    mise install
    # メモリ使用量を最適化するための設定（一般開発用途に適した1GB）
    export NODE_OPTIONS="--max-old-space-size=1024"
    export pnpm_store_dir="/tmp/.pnpm-store"
    export pnpm_cache_dir="/tmp/.pnpm-cache"
    
    echo "📦 Node.jsとpnpmをインストール中..."
else
    echo "⚠️  .mise.tomlファイルが見つかりません。デフォルトのツールをインストールします..."
    export NODE_OPTIONS="--max-old-space-size=1024"
    export pnpm_store_dir="/tmp/.pnpm-store"
    export pnpm_cache_dir="/tmp/.pnpm-cache"
    
    mise install node@lts
    mise install pnpm@latest
    mise use node@lts
    mise use pnpm@latest
fi

# miseの環境を確実に適用
echo "🔧 miseの環境を確実に適用中..."
mise reshim

# 環境変数を更新
export PATH="/root/.local/share/mise/shims:/root/.local/bin:$PATH"

# Node.js環境の確認
echo "📋 Node.js環境を確認中..."
node --version
npm --version

echo "📋 claude-codeをインストール中..."
npm install -g @anthropic-ai/claude-code

# ホストの設定ファイルを確認・コピー
echo "📋 ホストの設定ファイルを確認中..."

# VSCode拡張機能の確認
if [ -d "/root/.vscode/extensions" ]; then
    echo "✅ VSCode拡張機能ディレクトリがマウントされています"
    ls -la /root/.vscode/extensions | head -5
else
    echo "⚠️  VSCode拡張機能ディレクトリがマウントされていません"
fi

# Cursor設定の確認
if [ -d "/root/.cursor" ]; then
    echo "✅ Cursor設定ディレクトリがマウントされています"
    ls -la /root/.cursor
else
    echo "⚠️  Cursor設定ディレクトリがマウントされていません"
fi

echo "📋 Claude Code MCPサーバーをインストール中..."
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project $(pwd)


# 開発用の便利なエイリアスを設定
echo "🔧 開発用エイリアスを設定中..."
cat >> ~/.bashrc << 'ALIASES'

# Python開発用エイリアス
alias py='python'
alias pip='uv pip'
alias venv='uv venv'

# プロジェクト管理用エイリアス
alias dev='pnpm run dev'
alias build='pnpm run build'
alias test='pnpm run test'
alias lint='pnpm run lint'
ALIASES

# 環境変数を設定
echo "🔧 環境変数を設定中..."
cat >> ~/.bashrc << 'ENV_VARS'

# Python環境変数
export PYTHONPATH="/workspace:$PYTHONPATH"
export PATH="/workspace/node_modules/.bin:$PATH"

# mise環境変数（コンテナ起動時に自動適用）
export PATH="/root/.local/share/mise/shims:/root/.local/bin:$PATH"
export MISE_DATA_DIR="/root/.local/share/mise"
export MISE_CONFIG_DIR="/root/.config/mise"

# Cursor MCP環境変数
export CURSOR_CONFIG_PATH="/root/.cursor"
export CURSORRULES_PATH="/root/.cursorrules"

# メモリ使用量最適化のための環境変数（一般開発用途に適した1GB）
export NODE_OPTIONS="--max-old-space-size=1024"
export pnpm_store_dir="/tmp/.pnpm-store"
export pnpm_cache_dir="/tmp/.pnpm-cache"
ENV_VARS

# セットアップ完了メッセージ
echo ""
echo "✅ Serena AI Coding Agent DevContainer セットアップが完了しました！"
echo ""
echo "🔧 開発用コマンド:"
echo "  dev             - 開発サーバーを起動"
echo "  build           - プロジェクトをビルド"
echo "  test            - テストを実行"
echo "  lint            - リンターを実行"
echo ""
echo "📁 共有設定:"
echo "  - VSCode拡張機能: /root/.vscode/extensions"
echo "  - Cursor設定: /root/.cursor"
echo "  - Cursor Rules: /root/.cursorrules"
echo ""
echo "🚀 新しいターミナルを開くか、source ~/.bashrc を実行してエイリアスを有効にしてください"
echo ""

# miseの環境確認
echo "🔍 miseの環境確認:"
echo "  mise: $(mise --version)"
echo "  miseで管理されているNode.js: $(mise current node)"
echo "  miseで管理されているpnpm: $(mise current pnpm)"
echo "  PATH内のNode.js: $(which node)"
echo "  PATH内のpnpm: $(which pnpm)"
echo "  実際のNode.jsバージョン: $(node --version)"
echo "  実際のpnpmバージョン: $(pnpm --version)"
echo ""
