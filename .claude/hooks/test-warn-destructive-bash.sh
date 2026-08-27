#!/bin/bash
# warn-destructive-bash.sh の検出精度を実測するスクリプト
#
# 目的: 「警告が出ているつもり」を防ぐ。人間形（cd してから git）と
#       AI形（git -C <path>）の両方で、検出すべきものが検出され、
#       普段使いのコマンドが誤検知されないことを確認する。
#
# 使い方: bash .claude/hooks/test-warn-destructive-bash.sh

set -u

HOOK="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/warn-destructive-bash.sh"
PASS=0
FAIL=0

# t <名前> <コマンド> <期待: warn|pass>
t() {
  local name="$1" cmd="$2" want="$3"
  local out got
  out="$(CLAUDE_TOOL_ARG_COMMAND="$cmd" bash "$HOOK" 2>&1)"
  if [ -n "$out" ]; then got="warn"; else got="pass"; fi
  if [ "$got" = "$want" ]; then
    echo "  PASS  $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $name (期待=$want 実際=$got)"
    FAIL=$((FAIL + 1))
  fi
}

echo "== 検出すべき: 人間形（cd してから git / そのまま git）=="
t "force push"            "git push --force origin main"       warn
t "force push 短縮形"      "git push -f origin main"            warn
t "reset --hard"          "git reset --hard HEAD~1"            warn
t "clean -fd"             "git clean -fd"                      warn
t "checkout ."            "git checkout ."                     warn
t "restore ."             "git restore ."                      warn
t "rm -rf"                "rm -rf /tmp/scratch"                warn
t "rm -fr（順序違い）"      "rm -fr /tmp/scratch"                warn
t "cd してから reset"      "cd /tmp/x && git reset --hard"      warn
t "DROP TABLE"            "psql -c 'DROP TABLE users'"         warn

echo "== 検出すべき: AI形（git -C <path>）=="
t "-C force push"         "git -C /tmp/x push --force"         warn
t "-C reset --hard"       "git -C /tmp/x reset --hard"         warn
t "-C clean -fd"          "git -C /tmp/x clean -fd"            warn
t "-C checkout ."         "git -C /tmp/x checkout ."           warn

echo "== 誤検知してはいけない: 普段使い =="
t "通常 push"             "git push origin main"               pass
t "ブランチ名に -f を含む"  "git push origin my-feature"         pass
t "通常 commit"           "git commit -m 'fix'"                pass
t "status"                "git -C /tmp/x status"               pass
t "ファイル指定 checkout"  "git checkout main -- src/app.ts"    pass
t "rm 単体"               "rm /tmp/scratch/a.txt"              pass
t "空コマンド"             ""                                   pass

echo
echo "結果: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
