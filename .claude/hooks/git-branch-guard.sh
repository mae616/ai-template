#!/bin/bash
# PreToolUse (Bash) 前に実行されるフック
# 目的: main/master へのcommit/pushを機械的にブロックする（rules/git.mdの「直接push禁止」を仕組みで担保）

COMMAND="$CLAUDE_TOOL_ARG_COMMAND"

if ! echo "$COMMAND" | grep -qE '\bgit (commit|push)\b'; then
  exit 0
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "🚫 現在のブランチは '$BRANCH' です。.claude/rules/git.md によりmain/masterへの直接commit/pushは禁止されています。" >&2
  echo "💡 task/*・sprint/*・hotfix/* いずれかのブランチを作成してから作業してください。" >&2
  exit 2
fi

# 他ブランチからでも refspec 指定（HEAD:main / foo:main / origin main 等）で
# リモートの main/master を直接更新する push はブロックする
if echo "$COMMAND" | grep -qE '\bgit push\b' && \
   echo "$COMMAND" | grep -qE '(^| |:)(main|master)( |$)'; then
  echo "🚫 リモートの main/master を直接更新する push は .claude/rules/git.md により禁止されています。" >&2
  echo "💡 PR（sprint/* → main 等）を作成してマージ判断は人間に委ねてください。" >&2
  exit 2
fi

exit 0
