#!/bin/bash
set -euo pipefail

echo "🚀 Serena AI Coding Agent DevContainer セットアップを開始します..."
echo "ℹ️  setup.sh version: 2026-01-01"

# 冪等化のための共通関数
ensure_bashrc_block() {
    local marker_begin="# >>> ai-template devcontainer (BEGIN)"
    local marker_end="# <<< ai-template devcontainer (END)"
    local bashrc_file="${HOME}/.bashrc"

    touch "$bashrc_file"

    if grep -qF "$marker_begin" "$bashrc_file"; then
        echo "ℹ️  既に ~/.bashrc に ai-template の設定ブロックがあるため追記しません"
        return 0
    fi

    cat >> "$bashrc_file" << 'BASHRC_BLOCK'

# >>> ai-template devcontainer (BEGIN)
# Python開発用エイリアス
alias py='python'
alias pip='uv pip'
alias venv='uv venv'

# プロジェクト管理用エイリアス
alias dev='pnpm run dev'
alias build='pnpm run build'
alias test='pnpm run test'
alias lint='pnpm run lint'

# Python環境変数
export PYTHONPATH="/workspace:$PYTHONPATH"
export PATH="/workspace/node_modules/.bin:$PATH"

# mise環境変数（コンテナ起動時に自動適用）
export PATH="/root/.local/share/mise/shims:/root/.local/bin:$PATH"
export MISE_DATA_DIR="/root/.local/share/mise"
export MISE_CONFIG_DIR="/root/.config/mise"

# Cursor設定
export CURSOR_CONFIG_PATH="/root/.cursor"
export CURSORRULES_PATH="/root/.cursorrules"

# メモリ使用量最適化（一般開発用途に適した1GB）
export NODE_OPTIONS="--max-old-space-size=1024"
export pnpm_store_dir="/tmp/.pnpm-store"
export pnpm_cache_dir="/tmp/.pnpm-cache"
# <<< ai-template devcontainer (END)
BASHRC_BLOCK

    echo "✅ ~/.bashrc に ai-template の設定ブロックを追記しました"
}

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
# mise activate はシェルへevalして効かせるのが前提（非対話でもこのプロセス内に適用する）
eval "$(mise activate bash 2>/dev/null || true)"

# mise はセキュリティのため、未信頼の設定ファイル（例: /workspace/.mise.toml）を無視/確認する。
# DevContainerの初回起動で止まりやすいので、非対話で信頼する（失敗しても後続で再プロンプトされるだけなので致命にはしない）。
echo "🔐 mise設定ファイルの信頼状態を確認中..."
# `mise trust` はバージョン差があり得るので、複数パターンを試す（失敗しても後続でプロンプトが出るだけ）
if mise trust -a >/dev/null 2>&1; then
    echo "✅ mise trust -a: OK"
elif command -v yes >/dev/null 2>&1; then
    # `mise trust` のフラグ差異に依存しないために yes パイプを使う
    yes | mise trust >/dev/null 2>&1 || true
fi

ensure_gnupg_home() {
    # mise が起動する gpg と同じ鍵束を使えるよう、GNUPGHOME を明示する（将来の挙動差にも強い）
    export GNUPGHOME="${GNUPGHOME:-/root/.gnupg}"
    mkdir -p "$GNUPGHOME"
    chmod 700 "$GNUPGHOME"
}

import_gpg_pubkey_from_keyserver() {
    local key_fpr="$1"
    ensure_gnupg_home

    if ! command -v gpg >/dev/null 2>&1; then
        echo "❌ gpg が見つかりません。Dockerfile側で gnupg を導入してください" >&2
        exit 1
    fi
    if ! command -v curl >/dev/null 2>&1; then
        echo "❌ curl が見つかりません（鍵取得に必要）" >&2
        exit 1
    fi

    if gpg --batch --list-keys "$key_fpr" >/dev/null 2>&1; then
        return 0
    fi

    echo "🔑 GPG公開鍵をインポート中... (${key_fpr})"
    # keyserver を gpg で直接叩くと失敗する環境があるため、HTTPSで取得して import する
    curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${key_fpr}" | gpg --batch --import >/dev/null 2>&1 || {
        echo "❌ GPG公開鍵の取得/インポートに失敗しました（ネットワーク/DNS/鍵サーバー問題の可能性）" >&2
        exit 1
    }
}

extract_gpg_key_fpr_from_mise_log() {
    # mise/node の失敗ログ例:
    #   gpg:                using EDDSA key 86C8D7...
    # ここから 40桁hex指紋を抜く（将来別キーに変わっても追従）
    sed -nE 's/.*using (EDDSA|RSA|DSA|ECDSA) key ([0-9A-F]{16,40}).*/\\2/p' "$1" | head -n 1
}

mise_install_with_gpg_key_retry() {
    ensure_gnupg_home

    local max_attempts=3
    local attempt=1
    local log_file
    log_file="$(mktemp)"

    while [ "$attempt" -le "$max_attempts" ]; do
        : > "$log_file"
        echo "📦 mise install を実行中... (attempt ${attempt}/${max_attempts})"
        if mise install 2>&1 | tee "$log_file"; then
            rm -f "$log_file"
            return 0
        fi

        local key_fpr
        key_fpr="$(extract_gpg_key_fpr_from_mise_log "$log_file" || true)"
        if [ -n "${key_fpr:-}" ]; then
            echo "🧩 mise のログから必要なGPG鍵を検出: ${key_fpr}"
            import_gpg_pubkey_from_keyserver "$key_fpr"
            attempt=$((attempt + 1))
            continue
        fi

        echo "❌ mise install が失敗しました（GPG鍵指紋をログから抽出できませんでした）" >&2
        echo "---- mise log (tail) ----" >&2
        tail -n 60 "$log_file" >&2 || true
        rm -f "$log_file"
        return 1
    done

    echo "❌ mise install が繰り返し失敗しました（GPG鍵の自動導入後も解決しない）" >&2
    echo "---- mise log (tail) ----" >&2
    tail -n 60 "$log_file" >&2 || true
    rm -f "$log_file"
    return 1
}

# .mise.tomlに基づいてツールをインストール（メモリ使用量を最適化）
echo "🔧 .mise.tomlに基づいてツールをインストール中..."
if [ -f ".mise.toml" ]; then
    mise_install_with_gpg_key_retry
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
    
    # 署名鍵問題が出ても自動で追従できるよう、installはまとめて扱う
    mise install node@lts pnpm@latest
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
if command -v claude >/dev/null 2>&1; then
    echo "✅ claude-code は既にインストール済みです: $(claude --version 2>/dev/null || true)"
else
    npm install -g @anthropic-ai/claude-code
    # mise の shims 運用では、グローバルインストール後に reshim しないと新規コマンドが見えないことがある。
    echo "🔧 miseのshimsを更新中（claude を有効化）..."
    mise reshim
fi

# 期待するCLIが使えることをここで確定させる（ここで落ちれば原因が追いやすい）
if ! command -v claude >/dev/null 2>&1; then
    echo "❌ claude コマンドが見つかりません（インストール後のPATH/reshimが不整合の可能性）" >&2
    echo "   - PATH: $PATH" >&2
    echo "   - npm prefix: $(npm config get prefix 2>/dev/null || echo 'unknown')" >&2
    echo "   - node: $(which node 2>/dev/null || echo 'not-found') / $(node --version 2>/dev/null || echo 'unknown')" >&2
    echo "   - npm:  $(which npm  2>/dev/null || echo 'not-found') / $(npm --version 2>/dev/null || echo 'unknown')" >&2
    exit 1
fi
echo "✅ claude コマンドを確認しました: $(claude --version 2>/dev/null || true)"

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

# Figma公式（Dev Mode）MCPサーバーの接続設定（Cursor向け）
# - 注意: Figma Desktop（ホスト側）で Dev Mode MCP サーバーを有効化している必要があります。
# - DevContainer内からは 127.0.0.1 はコンテナ自身になるため、host.docker.internal 経由で接続します。
echo "📋 Figma（Dev Mode）MCPサーバーの接続設定を準備中..."
FIGMA_MCP_URL="${FIGMA_MCP_URL:-http://host.docker.internal:3845/mcp}"
CURSOR_MCP_FILE="/root/.cursor/mcp.json"
if [ -d "/root/.cursor" ]; then
    if [ -f "$CURSOR_MCP_FILE" ]; then
        echo "ℹ️  既に $CURSOR_MCP_FILE が存在するため上書きしません（必要なら figma サーバー定義を手動で追記してください）"
    else
        cat > "$CURSOR_MCP_FILE" << EOF
{
  "mcpServers": {
    "figma": {
      "url": "$FIGMA_MCP_URL"
    }
  }
}
EOF
        echo "✅ Cursor用Figma MCP設定を書き込みました: $CURSOR_MCP_FILE"
    fi
else
    echo "⚠️  /root/.cursor が無いためスキップします"
fi

echo "📋 Claude Code MCPサーバーをインストール中..."
if command -v claude >/dev/null 2>&1; then
    if (claude mcp list 2>/dev/null || true) | grep -qE '(^|\\s)serena(\\s|$)'; then
        echo "✅ Serena MCP は既に登録済みです（claude mcp list）"
    elif [ -f "/root/.claude/mcp-config.json" ] && grep -q '"serena"' "/root/.claude/mcp-config.json"; then
        echo "✅ Serena MCP は既に登録済みです（/root/.claude/mcp-config.json）"
    else
        claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project "$(pwd)"
    fi
else
    echo "⚠️  claude コマンドが見つからないため、Serena MCP の登録をスキップします"
fi


# 開発用の便利なエイリアスを設定
echo "🔧 ~/.bashrc を更新中（冪等）..."
ensure_bashrc_block

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
