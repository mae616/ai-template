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
npm install -g @anthropic-ai/claude-code
# mise の shims 運用では、グローバルインストール後に reshim しないと新規コマンドが見えないことがある。
echo "🔧 miseのshimsを更新中（claude を有効化）..."
mise reshim

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

echo "📋 ni（@antfu/ni）をインストール中..."
# lockfileに応じて正しいパッケージマネージャを選ぶための薄いラッパ（ni/nr/nlx 等）
npm install -g @antfu/ni
echo "🔧 miseのshimsを更新中（ni を有効化）..."
mise reshim
if ! command -v ni >/dev/null 2>&1; then
    echo "❌ ni コマンドが見つかりません（インストール後のPATH/reshimが不整合の可能性）" >&2
    echo "   - PATH: $PATH" >&2
    echo "   - npm prefix: $(npm config get prefix 2>/dev/null || echo 'unknown')" >&2
    exit 1
fi
echo "✅ ni コマンドを確認しました: $(ni -v 2>/dev/null || true)"

# ホストの設定ファイルを確認・コピー
echo "📋 ホストの設定ファイルを確認中..."

# VSCode拡張機能の確認
if [ -d "/root/.vscode/extensions" ]; then
    echo "✅ VSCode拡張機能ディレクトリがマウントされています"
    # `set -o pipefail` 下で `ls | head` を使うと、head 側が先に終了したときに
    # ls が SIGPIPE で失敗扱いになり、スクリプト全体が途中終了することがある。
    # ここはログ表示のため、失敗扱いにしない。
    ls -la /root/.vscode/extensions | head -5 || true
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

detect_figma_mcp_url() {
    # Figma Desktop（ホスト側）の Dev Mode MCP へ「コンテナ→ホスト」で到達するためのURLを決める。
    # - Docker: host.docker.internal が使えることが多い
    # - Podman: host.containers.internal が使えることが多い
    # - どちらも無い環境では、ユーザーが FIGMA_MCP_URL を明示する前提にする（推測で壊さない）
    local port="3845"
    local path="/mcp"

    is_reachable_http() {
        local url="$1"
        if ! command -v curl >/dev/null 2>&1; then
            return 1
        fi
        # 返ってくるHTTPステータスは問わず「到達できたか」だけを見る（000 は到達不能）
        local code
        code="$(curl -sS -o /dev/null -m 2 -w '%{http_code}' "$url" || true)"
        [ "$code" != "000" ]
    }

    host_exists() {
        local host="$1"
        command -v getent >/dev/null 2>&1 && getent hosts "$host" >/dev/null 2>&1
    }

    # Podman っぽい環境では host.containers.internal を優先する（host-gateway が無くても動かせる）
    local candidates=()
    if [ -f /run/.containerenv ] && grep -qi podman /run/.containerenv 2>/dev/null; then
        candidates+=("http://host.containers.internal:${port}${path}")
        candidates+=("http://host.docker.internal:${port}${path}")
    else
        candidates+=("http://host.docker.internal:${port}${path}")
        candidates+=("http://host.containers.internal:${port}${path}")
    fi

    # デフォルトゲートウェイIP（Docker on Linux 等で有効なことがある）
    if command -v ip >/dev/null 2>&1; then
        local gw_ip
        gw_ip="$(ip route show default 2>/dev/null | awk '{print $3}' | head -n 1)"
        if [ -n "${gw_ip:-}" ]; then
            candidates+=("http://${gw_ip}:${port}${path}")
        fi
    fi

    # まずは「名前解決できる」かつ「HTTP到達できる」候補を採用する
    local url host
    for url in "${candidates[@]}"; do
        host="$(echo "$url" | sed -nE 's#^https?://([^:/]+).*#\1#p')"
        if [[ "$host" == "host."* ]] && ! host_exists "$host"; then
            continue
        fi
        if is_reachable_http "$url"; then
            echo "$url"
            return 0
        fi
    done

    # 最後のフォールバック（固定値）。到達不能なら README の手順に従い FIGMA_MCP_URL を上書きする。
    echo "http://host.docker.internal:${port}${path}"
}

FIGMA_MCP_URL="${FIGMA_MCP_URL:-$(detect_figma_mcp_url)}"

echo "📋 Claude Code MCPサーバーをインストール中..."
export CLAUDE_CONFIG_PATH="${CLAUDE_CONFIG_PATH:-/root/.claude}"
mkdir -p "$CLAUDE_CONFIG_PATH"

echo "📋 Claude MCP 現在の登録状況（事前）:"
(claude mcp list 2>/dev/null || true)

echo "📋 Serena MCP を Claude Code に登録します"
if ! claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project "$(pwd)"; then
    echo "❌ Serena MCP の登録に失敗しました" >&2
    echo "📋 Claude MCP 登録状況（失敗時）:" >&2
    (claude mcp list 2>/dev/null || true) >&2
    echo "📋 claude doctor（失敗時）:" >&2
    (claude doctor 2>/dev/null || true) >&2
    exit 1
fi

echo "📋 Figma MCP を Claude Code に登録します: ${FIGMA_MCP_URL}"
if ! claude mcp add --transport http figma "${FIGMA_MCP_URL}"; then
    echo "❌ Figma MCP の登録に失敗しました" >&2
    echo "   - FIGMA_MCP_URL: ${FIGMA_MCP_URL}" >&2
    echo "📋 Claude MCP 登録状況（失敗時）:" >&2
    (claude mcp list 2>/dev/null || true) >&2
    echo "📋 claude doctor（失敗時）:" >&2
    (claude doctor 2>/dev/null || true) >&2
    exit 1
fi

echo "📋 Claude MCP 登録状況（事後）:"
(claude mcp list 2>/dev/null || true)


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
