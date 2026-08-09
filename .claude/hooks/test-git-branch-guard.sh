#!/bin/bash
# git-branch-guard.sh の検証スクリプト
#
# 目的: ガードが「止めるべきを止め、通すべきを通す」ことを実測する。
# ガード系フックは書いて終わりにすると、効いていないのに「守られている」と誤認する。
# 修正のたびにこれを流し、通す/止める両方を確認する。
#
# 使い方: bash .claude/hooks/test-git-branch-guard.sh
# 作業用リポジトリは一時ディレクトリに作るため、このリポジトリは汚さない。

set -u

HOOK="$(cd "$(dirname "$0")" && pwd)/git-branch-guard.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 検証用リポジトリを2つ用意する。
#   SAFE_REPO … task ブランチ（通ってほしい）
#   MAIN_REPO … main ブランチ（止まってほしい）
SAFE_REPO="$WORK/safe"
MAIN_REPO="$WORK/main"
EMPTY_REPO="$WORK/empty"   # コミット0件。rev-parse 系の穴を踏む条件

for r in "$SAFE_REPO" "$MAIN_REPO" "$EMPTY_REPO"; do
  git init -q -b main "$r"
  git -C "$r" config user.email t@example.com
  git -C "$r" config user.name t
done
# EMPTY_REPO だけコミットを作らない（初回コミットの瞬間を再現する）
for r in "$SAFE_REPO" "$MAIN_REPO"; do
  git -C "$r" commit -q --allow-empty -m init
done
git -C "$SAFE_REPO" checkout -q -b task/test

PASS=0
FAIL=0

# t <ケース名> <コマンド文字列> <期待exit>
# 期待exit: 0=通す / 2=止める
t() {
  local name="$1" cmd="$2" want="$3"
  local got
  # cwd は Git 管理外に置く。cwd 依存で誤って通していないかを同時に検証する。
  (cd "$WORK" && CLAUDE_TOOL_ARG_COMMAND="$cmd" bash "$HOOK" >/dev/null 2>&1)
  got=$?
  if [ "$got" = "$want" ]; then
    echo "  PASS  $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $name (期待=$want 実際=$got)"
    FAIL=$((FAIL + 1))
  fi
}

echo "git-branch-guard.sh 検証"

# 通すべきケース
t "git以外のコマンドは素通り"      'ls -la'                                        0
t "-C で task ブランチ"            "git -C $SAFE_REPO commit -m x"                 0
t "cd で task ブランチ"            "cd $SAFE_REPO && git commit -m x"              0
t "-C で task を push"             "git -C $SAFE_REPO push origin HEAD"            0

# 止めるべきケース（main への直接操作）
t "-C で main に commit"           "git -C $MAIN_REPO commit -m x"                 2
t "cd で main に commit"           "cd $MAIN_REPO && git commit -m x"              2
t "-C で main に push"             "git -C $MAIN_REPO push"                        2
t "task から main へ refspec push" "git -C $SAFE_REPO push origin HEAD:main"       2

# 止めるべきケース（fail-closed）
t "ブランチ判定不能なら止める"     'git commit -m x'                               2
t "コミット0件のリポジトリのmain"  "git -C $EMPTY_REPO commit -m x"                2

echo "----"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
