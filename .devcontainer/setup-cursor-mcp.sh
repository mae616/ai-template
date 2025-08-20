#!/bin/bash
set -e

echo "🚀 Cursor MCPサーバー設定をセットアップ中..."

# メモリ使用量を削減するための設定
export NODE_OPTIONS="--max-old-space-size=512"
export npm_config_cache="/tmp/.npm"
export npm_config_prefer_offline=true

# ホストのCursor設定ディレクトリを確認
CURSOR_HOST_DIR="${HOME}/.cursor"
CURSORRULES_HOST_FILE="${HOME}/.cursorrules"

# コンテナ内の設定ディレクトリ
CURSOR_CONTAINER_DIR="/root/.cursor"
CURSORRULES_CONTAINER_FILE="/root/.cursorrules"

echo "📋 ホストのCursor設定ディレクトリを確認中..."

# Cursor設定の確認とコピー
if [ -d "$CURSOR_HOST_DIR" ]; then
    echo "✅ ホストのCursor設定を発見: $CURSOR_HOST_DIR"
    
    # コンテナ内のディレクトリが存在しない場合は作成
    if [ ! -d "$CURSOR_CONTAINER_DIR" ]; then
        mkdir -p "$CURSOR_CONTAINER_DIR"
    fi
    
    # 設定ファイルをコピー
    echo "📋 Cursor設定をコピー中..."
    cp -r "$CURSOR_HOST_DIR"/* "$CURSOR_CONTAINER_DIR/" 2>/dev/null || true
    
    echo "✅ Cursor設定をコピー完了"
else
    echo "⚠️  ホストのCursor設定ディレクトリが見つかりません: $CURSOR_HOST_DIR"
fi

# Cursor Rulesファイルの確認とコピー
if [ -f "$CURSORRULES_HOST_FILE" ]; then
    echo "✅ ホストのCursor Rulesファイルを発見: $CURSORRULES_HOST_FILE"
    
    # 設定ファイルをコピー
    echo "📋 Cursor Rulesファイルをコピー中..."
    cp "$CURSORRULES_HOST_FILE" "$CURSORRULES_CONTAINER_FILE" 2>/dev/null || true
    
    echo "✅ Cursor Rulesファイルをコピー完了"
else
    echo "⚠️  ホストのCursor Rulesファイルが見つかりません: $CURSORRULES_HOST_FILE"
fi

# Cursor用のMCP設定ファイルを作成
echo "⚙️  Cursor用のMCP設定ファイルを作成中..."

cat > "$CURSOR_CONTAINER_DIR/mcp-config.json" << 'MCP_CONFIG'
{
    "mcpServers": {
        "cursor": {
            "command": "npx",
            "args": ["-y", "@cursor/mcp-server"],
            "env": {}
        }
    }
}
MCP_CONFIG

# 環境変数ファイルを作成（存在しない場合）
if [ ! -f "$CURSOR_CONTAINER_DIR/.env" ]; then
    echo "🔑 環境変数ファイルを作成中..."
    cat > "$CURSOR_CONTAINER_DIR/.env" << 'ENV_FILE'
# Cursor MCP Server 環境変数
CURSOR_MODEL=claude-3.5-sonnet-20241022
MCP_SERVER_PORT=8002
ENV_FILE
fi

# 権限を設定
chmod 600 "$CURSOR_CONTAINER_DIR/.env" 2>/dev/null || true
chmod 644 "$CURSOR_CONTAINER_DIR/mcp-config.json"

# Cursor MCPサーバーを起動（バックグラウンドで、メモリ使用量を最小限に）
echo "🚀 Cursor MCPサーバーを起動中..."
if pgrep -f "cursor" > /dev/null; then
    echo "✅ Cursor MCPサーバーは既に起動中です"
else
    # サーバーを起動（メモリ使用量を制限）
    echo "📦 Cursor MCPサーバーをダウンロード中..."
    echo "⚠️  初回起動時は時間がかかる場合があります..."
    
    # メモリ使用量を制限してサーバーを起動
    nohup node --max-old-space-size=512 -e "
        const { spawn } = require('child_process');
        const server = spawn('npx', ['-y', '@cursor/mcp-server'], {
            stdio: ['pipe', 'pipe', 'pipe'],
            env: { ...process.env, NODE_OPTIONS: '--max-old-space-size=512' }
        });
        server.stdout.pipe(process.stdout);
        server.stderr.pipe(process.stderr);
    " > /tmp/cursor-mcp.log 2>&1 &
    
    echo "✅ Cursor MCPサーバーを起動しました (PID: $!)"
    echo "📋 ログファイル: /tmp/cursor-mcp.log"
fi

# サーバーの状態を確認
sleep 3
if pgrep -f "cursor" > /dev/null; then
    echo "✅ Cursor MCPサーバーが正常に起動しています"
    echo "🔍 プロセス情報:"
    ps aux | grep "cursor" | grep -v grep
else
    echo "❌ Cursor MCPサーバーの起動に失敗しました"
    echo "📋 ログファイルの内容:"
    tail -20 /tmp/cursor-mcp.log 2>/dev/null || echo "ログファイルが見つかりません"
    echo ""
    echo "💡 メモリ不足の可能性があります。以下の対策を試してください："
    echo "   1. コンテナのメモリ制限を増やす"
    echo "   2. 他のプロセスを停止する"
    echo "   3. システムのメモリを解放する"
fi

echo ""
echo "✅ Cursor MCPサーバー設定が完了しました！"
echo ""
echo "📋 設定内容:"
echo "  - Cursor設定: $CURSOR_CONTAINER_DIR"
echo "  - Cursor Rules: $CURSORRULES_CONTAINER_FILE"
echo "  - MCP設定ファイル: $CURSOR_CONTAINER_DIR/mcp-config.json"
echo "  - 環境変数ファイル: $CURSOR_CONTAINER_DIR/.env"
echo ""
echo "🔧 管理コマンド:"
echo "  cursor-mcp-start  - Cursor MCPサーバーを起動"
echo "  cursor-mcp-status - Cursor MCPサーバーの状態を確認"
echo "  cursor-mcp-stop   - Cursor MCPサーバーを停止"
echo ""
echo "🌐 利用可能なポート:"
echo "  - 8000: Serena MCP Server"
echo "  - 8001: Claude Code MCP Server"
echo "  - 8002: Cursor MCP Server"
echo "  - 3000: Development Server"
echo "  - 5173: Vite Dev Server"
echo "  - 8888: Jupyter Notebook"
echo ""
echo "📋 現在の状態:"
if pgrep -f "cursor" > /dev/null; then
    echo "  ✅ Cursor MCPサーバー: 起動中"
else
    echo "  ❌ Cursor MCPサーバー: 停止中"
fi
echo ""
echo "💾 メモリ使用量削減設定:"
echo "  - NODE_OPTIONS: --max-old-space-size=512"
echo "  - npm cache: /tmp/.npm"
echo "  - npm prefer-offline: true"
