#!/bin/bash
# PreToolUse (Bash) 前に実行されるフック
# 目的: main/master へのcommit/pushを機械的にブロックする（rules/git.mdの「直接push禁止」を仕組みで担保）

COMMAND="$CLAUDE_TOOL_ARG_COMMAND"

# `git` とサブコマンドの間にオプションが挟まる形（git -C <path> commit 等）も拾う。
# 隣接前提の '\bgit (commit|push)\b' だと -C 形式を取り逃がし、ガードが素通りする。
# パイプ・リダイレクト等をまたいで誤検知しないよう、区切り文字は挟まない範囲に限定する。
if ! echo "$COMMAND" | grep -qE '\bgit\b[^|;&]*\b(commit|push)\b'; then
  exit 0
fi

# 判定対象のリポジトリを決める。
#
# このフックはコマンドの実行「前」に走る。そのためカレントディレクトリだけを見ると、
# 次の2形式でブランチを取り違え、別リポジトリへのcommitを素通りさせてしまう。
#   1. git -C <path> commit     … -C で別リポジトリを指しているのに、cwd を見てしまう
#   2. cd <path> && git commit  … cd がまだ効いていないので、移動前の cwd を見てしまう
# どちらもコマンド文字列からパスを拾って、そのパス基準で判定する。
REPO_DIR=""
if [[ "$COMMAND" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
  REPO_DIR="${BASH_REMATCH[1]}"
elif [[ "$COMMAND" =~ (^|[\;\&\|][[:space:]]*)cd[[:space:]]+([^[:space:]\&\|\;]+) ]]; then
  REPO_DIR="${BASH_REMATCH[2]}"
fi

# クォートとチルダを剥がす（git -C にそのまま渡すと解決できないため）
REPO_DIR="${REPO_DIR%[\"\']}"
REPO_DIR="${REPO_DIR#[\"\']}"
REPO_DIR="${REPO_DIR/#\~/$HOME}"

# rev-parse --abbrev-ref HEAD は使わない。コミット0件のリポジトリでは
# 失敗しつつ文字列 "HEAD" を出力するため、main と一致せずガードが素通りする。
# branch --show-current は同じ状況でも "main" を返す。
if [[ -n "$REPO_DIR" ]]; then
  BRANCH="$(git -C "$REPO_DIR" branch --show-current 2>/dev/null)"
else
  BRANCH="$(git branch --show-current 2>/dev/null)"
fi

# ブランチを特定できないまま commit/push を通すと、ガードが素通りする。
# 判定不能は安全側に倒して止める（fail-closed）。
if [[ -z "$BRANCH" ]]; then
  echo "🚫 対象リポジトリのブランチを判定できませんでした。ガードが働かないため中断します。" >&2
  echo "💡 リポジトリのディレクトリで実行するか、git -C <path> でリポジトリを明示してください。" >&2
  exit 2
fi

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "🚫 現在のブランチは '$BRANCH' です。.claude/rules/git.md によりmain/masterへの直接commit/pushは禁止されています。" >&2
  echo "💡 task/*・sprint/*・hotfix/* いずれかのブランチを作成してから作業してください。" >&2
  exit 2
fi

# 他ブランチからでも refspec 指定（HEAD:main / foo:main / origin main 等）で
# リモートの main/master を直接更新する push はブロックする
# ここも入口と同じくオプション挟み込み（git -C <path> push）に対応させる
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&]*\bpush\b' && \
   echo "$COMMAND" | grep -qE '(^| |:)(main|master)( |$)'; then
  echo "🚫 リモートの main/master を直接更新する push は .claude/rules/git.md により禁止されています。" >&2
  echo "💡 PR（sprint/* → main 等）を作成してマージ判断は人間に委ねてください。" >&2
  exit 2
fi

exit 0
