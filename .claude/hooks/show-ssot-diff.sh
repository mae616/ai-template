#!/bin/bash
# PostToolUse (Write|Edit|Bash) 後に実行されるフック
# 目的: 確定物（合意済みSSOT）が書き換わったとき、その差分を必ず目に見える形で出す
#
# 設計の要点:
#   - 止めない。見せるだけ（作業は流れる。見えないまま入ることだけを無くす）
#   - ツール名では判定しない。AIは Write/Edit ではなく Bash(sed/heredoc/python) でも書く。
#     何で書いても差分は git の作業ツリーに出るので、そこを見る（迂回路を作らない）
#   - 前回から変化が無ければ黙る（同じ差分を毎回出さない）
#
# 対象: 書かれたら次セッションで「決まっていること」として前提になるファイル（ADR-026）

set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# 確定物のパス。ここに入ったものは合意の対象
TARGETS=(
  "doc/input/"
  "meta/adr-lite.md"
  "CLAUDE.md"
  ".claude/rules/"
)

# 未コミットの変更（staged + unstaged）を対象にする
CHANGED="$(git diff HEAD --name-only -- "${TARGETS[@]}" 2>/dev/null)"
[ -z "$CHANGED" ] && exit 0

# 同じ内容を繰り返し出さないよう、前回のハッシュと比較する
STATE_FILE="$(git rev-parse --git-dir 2>/dev/null)/ssot-diff-shown"
CURRENT_HASH="$(git diff HEAD -- "${TARGETS[@]}" 2>/dev/null | shasum | awk '{print $1}')"
PREV_HASH="$(cat "$STATE_FILE" 2>/dev/null || true)"
[ "$CURRENT_HASH" = "$PREV_HASH" ] && exit 0
printf '%s' "$CURRENT_HASH" > "$STATE_FILE" 2>/dev/null || true

STAT="$(git diff HEAD --stat -- "${TARGETS[@]}" 2>/dev/null)"
LINES="$(git diff HEAD --numstat -- "${TARGETS[@]}" 2>/dev/null | awk '{a+=$1; d+=$2} END {print a+d}')"
LINES="${LINES:-0}"

echo "════════════════════════════════════════════════════════"
echo "📌 確定物（合意済みSSOT）に未コミットの変更があります"
echo "   ここに入ったものは、次のセッションで「決まっていること」として扱われます"
echo "────────────────────────────────────────────────────────"
echo "$STAT"

# CLI で読める量なら本文を出す。多ければ案内に留める（端末を埋めない）
THRESHOLD=60
if [ "$LINES" -le "$THRESHOLD" ]; then
  echo "────────────────────────────────────────────────────────"
  # delta 等の pager が設定されていてもフック内では素の差分を出す
  git --no-pager diff HEAD --no-color -- "${TARGETS[@]}" 2>/dev/null \
    | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | head -80
else
  echo "────────────────────────────────────────────────────────"
  echo "  差分が ${LINES} 行あるため本文は省略しました。次で確認できます:"
  echo "    git diff HEAD -- doc/input/ meta/adr-lite.md CLAUDE.md .claude/rules/"
fi
echo "════════════════════════════════════════════════════════"

exit 0
