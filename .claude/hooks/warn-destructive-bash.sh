#!/bin/bash
# PreToolUse (Bash) 前に実行されるフック
# 目的: 破壊的コマンド実行前に警告
#
# 注意: AIは `cd` せずに `git -C <path> reset --hard` の形を好む。
# 素朴に "git reset" で照合すると、この形が丸ごと素通りする（実測で確認済み）。
# 判定前に `git -C <path>` を `git` へ正規化して、人間形・AI形の両方を同じ土俵に乗せる。

COMMAND="$CLAUDE_TOOL_ARG_COMMAND"

[ -z "$COMMAND" ] && exit 0

# `git -C /path/to/repo push` → `git push` に正規化してから判定する
NORMALIZED="$(printf '%s' "$COMMAND" | sed -E 's/git[[:space:]]+-C[[:space:]]+[^[:space:]]+/git/g')"

# 破壊的コマンドパターン
# パイプ・連結記号をまたいで誤検知しないよう、オプション部分は [^;&|]* で受ける
DESTRUCTIVE_PATTERNS=(
  "git push[^;&|]*--force"
  "git push[^;&|]*[[:space:]]-[a-zA-Z]*f([[:space:]]|$)"
  "git reset[^;&|]*--hard"
  "git clean[^;&|]*[[:space:]]-[a-zA-Z]*f"
  "git checkout[[:space:]]+\.([[:space:]]|$)"
  "git restore[[:space:]]+\.([[:space:]]|$)"
  "rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f"
  "rm[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*r"
  "rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*/([[:space:]]|$)"
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE"
)

for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
  if printf '%s' "$NORMALIZED" | grep -qE "$pattern"; then
    echo "⚠️  破壊的コマンド検出: $pattern"
    echo "💡 このコマンドは取り消しが困難です。実行前に確認してください。"
    echo "---"
    echo "コマンド: $COMMAND"
    exit 0  # 警告のみ、ブロックはしない（止めるのは git-branch-guard.sh の役割）
  fi
done

exit 0
