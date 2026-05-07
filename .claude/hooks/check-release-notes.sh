#!/bin/bash
# セッション開始時にClaude Codeのバージョン更新を検出し、リリースノート確認を促すフック
# 一時利用ではなく常駐用。削除不可。

VERSION_FILE="$HOME/.claude/last-seen-version"
CURRENT_VERSION=$(claude --version 2>/dev/null | head -1 | sed 's/ .*//')

# バージョン取得失敗時は何もしない
if [ -z "$CURRENT_VERSION" ]; then
  exit 0
fi

# 前回バージョンを読み込み
LAST_VERSION=""
if [ -f "$VERSION_FILE" ]; then
  LAST_VERSION=$(cat "$VERSION_FILE")
fi

# バージョンが同じなら何もしない
if [ "$CURRENT_VERSION" = "$LAST_VERSION" ]; then
  exit 0
fi

# 新バージョンを記録
echo "$CURRENT_VERSION" > "$VERSION_FILE"

# 初回起動（前回バージョンなし）はサイレントに記録のみ
if [ -z "$LAST_VERSION" ]; then
  exit 0
fi

# バージョン更新を検出 → systemMessage で Claude に通知
cat <<EOF
{"systemMessage": "Claude Code が v${LAST_VERSION} → v${CURRENT_VERSION} に更新されましたにゃ。詳細は /release-notes で確認できるにゃ。"}
EOF
