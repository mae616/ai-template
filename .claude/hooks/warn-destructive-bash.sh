#!/bin/bash
# PreToolUse (Bash) 前に実行されるフック
# 目的: 破壊的コマンド実行前に警告

COMMAND="$CLAUDE_TOOL_ARG_COMMAND"

# 破壊的コマンドパターン
DESTRUCTIVE_PATTERNS=(
  "git push.*--force"
  "git push.*-f"
  "git reset --hard"
  "git clean -f"
  "git checkout \."
  "git restore \."
  "rm -rf"
  "rm -r /"
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE"
)

for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "⚠️  破壊的コマンド検出: $pattern"
    echo "💡 このコマンドは取り消しが困難です。実行前に確認してください。"
    echo "---"
    echo "コマンド: $COMMAND"
    exit 0  # 警告のみ、ブロックはしない
  fi
done
