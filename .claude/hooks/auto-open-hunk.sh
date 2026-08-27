#!/bin/bash
# PostToolUse (Write|Edit|Bash) 後に実行されるフック
# 目的: 変更が出たとき、差分ビューア hunk を split ペインで「1回だけ」開く
#
# 設計の要点:
#   - hunk は watch 状態で開くため、一度開けば以降の変更は自動で追随する。
#     編集のたびに開き直すと画面が何度も分割されるので、起動していない時だけ開く
#   - 「開いたか」を状態ファイルで推測せず、hunk daemon に実際の起動状態を問い合わせる
#     （ユーザーが手で閉じた場合も正しく判定できる）
#   - herdr の外では何もしない（split ペインという概念が無いため）
#   - CLAUDE_AUTO_HUNK=0 で無効化できる（画面が分割されるのを好まない場合）

set -uo pipefail

# 明示的に切られていたら何もしない
[ "${CLAUDE_AUTO_HUNK:-1}" = "0" ] && exit 0

# herdr の中でなければ split ペインを開けない
[ "${HERDR_ENV:-}" = "1" ] || exit 0

# 必要なコマンドが無ければ黙って終わる（環境依存のため落とさない）
command -v hunk >/dev/null 2>&1 || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# 変更が無ければ開かない（未追跡ファイルも変更として扱う）
[ -z "$(git status --porcelain 2>/dev/null)" ] && exit 0

# 既に hunk が起動していれば開かない。watch が差分を追い続けている
SESSIONS="$(hunk session list --json 2>/dev/null || echo '{"sessions": []}')"
if ! printf '%s' "$SESSIONS" | tr -d ' \n' | grep -q '"sessions":\[\]'; then
  exit 0
fi

# ここまで来たら未起動。split で開く。
# 投げっぱなし（&）にはしない。結果を確認できない形は「開いたつもり」を生む。
# 応答しない場合は settings.json の timeout が守る。
if herdr plugin action invoke worktree-split --plugin hunk.diff >/dev/null 2>&1; then
  echo "🔍 差分ビューア hunk を split で開きました（watch状態。以降の変更は自動で追随します）"
  echo "   閉じたい場合はそのペインを閉じてください。自動起動を止めるには CLAUDE_AUTO_HUNK=0"
else
  echo "⚠️  hunk の split 起動に失敗しました（herdr plugin action invoke が非0で終了）"
fi

exit 0
