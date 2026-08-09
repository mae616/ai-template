#!/bin/bash
# PostToolUse (Write|Edit) 後に実行されるフック
# 目的: 編集直後にPrettier/ESLintを静かに適用し、フォーマットだけのコミットを無くす

FILE_PATH="$CLAUDE_TOOL_ARG_FILE_PATH"

[ -z "$FILE_PATH" ] && exit 0
[ -f "$FILE_PATH" ] || exit 0

case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.md)
    ;;
  *)
    exit 0
    ;;
esac

if command -v npx >/dev/null 2>&1 && [ -f "package.json" ]; then
  npx --no-install prettier --write "$FILE_PATH" >/dev/null 2>&1
  npx --no-install eslint --fix "$FILE_PATH" >/dev/null 2>&1
fi

exit 0
