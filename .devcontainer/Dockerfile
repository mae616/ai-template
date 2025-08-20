FROM ubuntu:22.04

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# システムパッケージの更新と必要最小限のパッケージのインストール
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Pythonのシンボリックリンクを作成
RUN ln -sf /usr/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/bin/pip3 /usr/local/bin/pip

# uv（Pythonパッケージマネージャー）のインストール
RUN pip install --no-cache-dir uv

# miseインストール
RUN curl -fsSL https://mise.run | sh

# miseの環境変数を設定
ENV PATH="/root/.local/share/mise/shims:/root/.local/bin:$PATH"
ENV MISE_DATA_DIR="/root/.local/share/mise"
ENV MISE_CONFIG_DIR="/root/.config/mise"

# uvとmiseをシステム全体で利用できるようにする
RUN ln -sf /root/.local/bin/mise /usr/local/bin/mise

# 基本的な開発ツールのインストール（必要最小限）
RUN apt-get update && apt-get install -y \
    ripgrep \
    fd-find \
    && rm -rf /var/lib/apt/lists/*

# Python依存関係のインストール
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# 開発に必要なPythonパッケージをインストール
RUN pip install --no-cache-dir \
    black \
    isort \
    flake8 \
    pytest \
    ipython

# VSCode Server用のディレクトリ作成
RUN mkdir -p /root/.vscode-server/extensions

# 作業ディレクトリ
WORKDIR /workspace

# Podman対応: ヘルスチェック（軽量化）
HEALTHCHECK --interval=60s --timeout=5s --start-period=10s --retries=2 \
    CMD python3 --version || exit 1
