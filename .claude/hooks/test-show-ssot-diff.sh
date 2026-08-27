#!/bin/bash
# show-ssot-diff.sh の検証スクリプト
# 「見せる」「黙る」の両方を実測する。フックを直したら毎回これを流す。
#
# 使い捨ての git リポジトリを /tmp に作って試すので、このリポジトリは汚さない。

set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/show-ssot-diff.sh"
PASS=0; FAIL=0

setup() {
  SANDBOX="$(mktemp -d)"
  cd "$SANDBOX" || exit 1
  git init -q .
  git config user.email t@example.com
  git config user.name test
  mkdir -p doc/input meta .claude/rules
  echo "初期" > doc/input/rdd.md
  echo "初期" > meta/adr-lite.md
  echo "初期" > CLAUDE.md
  echo "初期" > .claude/rules/dev-practices.md
  echo "初期" > README.md
  git add -A && git commit -qm init
}
teardown() { cd /tmp && rm -rf "$SANDBOX"; }

run_hook() { CLAUDE_PROJECT_DIR="$SANDBOX" bash "$HOOK" 2>&1; }

check() {
  local name="$1" expect="$2" out="$3"
  if [ "$expect" = "見せる" ]; then
    if echo "$out" | grep -q "確定物"; then echo "  ✅ $name → 見せた"; PASS=$((PASS+1));
    else echo "  ❌ $name → 見せるべきなのに黙った"; FAIL=$((FAIL+1)); fi
  else
    if [ -z "$(echo "$out" | tr -d '[:space:]')" ]; then echo "  ✅ $name → 黙った"; PASS=$((PASS+1));
    else echo "  ❌ $name → 黙るべきなのに出力した"; FAIL=$((FAIL+1)); fi
  fi
}

echo "=== show-ssot-diff.sh 検証 ==="

# 1. 変更なし → 黙る
setup
check "変更なし" "黙る" "$(run_hook)"
teardown

# 2. CLAUDE.md を変更 → 見せる
setup
echo "AIが勝手に足した判断" >> CLAUDE.md
check "CLAUDE.md 変更" "見せる" "$(run_hook)"
teardown

# 3. rdd.md を Bash(heredoc) で書き換え → 見せる（ツール非依存の確認）
setup
cat >> doc/input/rdd.md <<'EOS'
⚠️ 合意していない設計判断
EOS
check "Bashで rdd.md 書き換え" "見せる" "$(run_hook)"
teardown

# 4. adr-lite.md を sed で書き換え → 見せる
setup
sed -i.bak 's/初期/AIが書いたADR/' meta/adr-lite.md && rm -f meta/adr-lite.md.bak
check "sedで adr-lite 書き換え" "見せる" "$(run_hook)"
teardown

# 5. .claude/rules/ を変更 → 見せる
setup
echo "新ルール" >> .claude/rules/dev-practices.md
check ".claude/rules 変更" "見せる" "$(run_hook)"
teardown

# 6. 確定物以外（README.md）だけ変更 → 黙る
setup
echo "ただの説明追記" >> README.md
check "README.md だけ変更" "黙る" "$(run_hook)"
teardown

# 7. 同じ差分で2回目 → 黙る（重複表示しない）
setup
echo "追記" >> CLAUDE.md
run_hook >/dev/null
check "同じ差分で2回目" "黙る" "$(run_hook)"
teardown

# 8. 2回目のあとさらに変更 → また見せる
setup
echo "追記1" >> CLAUDE.md
run_hook >/dev/null
echo "追記2" >> CLAUDE.md
check "さらに変更したら" "見せる" "$(run_hook)"
teardown

# 9. 大きい差分 → 本文は省略して案内を出す
setup
for i in $(seq 1 100); do echo "行 $i" >> doc/input/rdd.md; done
OUT="$(run_hook)"
if echo "$OUT" | grep -q "本文は省略"; then echo "  ✅ 大きい差分 → 省略して案内"; PASS=$((PASS+1));
else echo "  ❌ 大きい差分 → 端末を埋めている"; FAIL=$((FAIL+1)); fi
teardown

# 10. git 管理外のディレクトリ → 落ちずに黙る
SANDBOX="$(mktemp -d)"
check "git管理外" "黙る" "$(CLAUDE_PROJECT_DIR="$SANDBOX" bash "$HOOK" 2>&1)"
rm -rf "$SANDBOX"

echo
echo "結果: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
