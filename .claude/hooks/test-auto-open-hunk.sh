#!/bin/bash
# auto-open-hunk.sh の検証スクリプト
# 「開く」「開かない」の両方を実測する。
# herdr / hunk はスタブに差し替えるので、実際にペインは開かない。

set -uo pipefail
HOOK="$(cd "$(dirname "$0")" && pwd)/auto-open-hunk.sh"
PASS=0; FAIL=0

setup() {
  SANDBOX="$(mktemp -d)"; STUB="$(mktemp -d)"
  # stub は SANDBOX の外に置く。中に置くと git status に未追跡として出て判定が狂う
  cd "$SANDBOX" || exit 1
  git init -q .; git config user.email t@e.com; git config user.name t
  echo "初期" > a.txt; git add -A; git commit -qm init

  # herdr スタブ: 呼ばれたら invoked ファイルを作る
  cat > "$STUB/herdr" <<'EOS'
#!/bin/bash
[ "$1" = "plugin" ] && echo "$@" >> "$STUB_INVOKED"
exit 0
EOS
  # hunk スタブ: セッション一覧を SESSIONS_JSON で差し替えられる
  cat > "$STUB/hunk" <<'EOS'
#!/bin/bash
if [ "$1" = "session" ]; then printf '%s' "${SESSIONS_JSON:-{\"sessions\": []\}}"; fi
exit 0
EOS
  chmod +x "$STUB/herdr" "$STUB/hunk"
  export STUB_INVOKED="$SANDBOX/invoked"
}
teardown() { cd /tmp && rm -rf "$SANDBOX" "$STUB"; }

run() {
  env PATH="$STUB:$PATH" CLAUDE_PROJECT_DIR="$SANDBOX" STUB_INVOKED="$STUB_INVOKED" \
      "$@" bash "$HOOK" >/dev/null 2>&1
}
opened() { [ -f "$STUB_INVOKED" ]; }

check() {
  local name="$1" expect="$2"
  if [ "$expect" = "開く" ]; then
    if opened; then echo "  ✅ $name → 開いた"; PASS=$((PASS+1)); else echo "  ❌ $name → 開くべきなのに開かない"; FAIL=$((FAIL+1)); fi
  else
    if opened; then echo "  ❌ $name → 開くべきでないのに開いた"; FAIL=$((FAIL+1)); else echo "  ✅ $name → 開かなかった"; PASS=$((PASS+1)); fi
  fi
}

echo "=== auto-open-hunk.sh 検証 ==="

# 1. 変更あり・herdr内・セッション無し → 開く
setup; echo "変更" >> a.txt
run HERDR_ENV=1
check "変更あり/herdr内/未起動" "開く"; teardown

# 2. herdr の外 → 開かない
setup; echo "変更" >> a.txt
run HERDR_ENV=
check "herdrの外" "開かない"; teardown

# 3. 明示的に無効化 → 開かない
setup; echo "変更" >> a.txt
run HERDR_ENV=1 CLAUDE_AUTO_HUNK=0
check "CLAUDE_AUTO_HUNK=0" "開かない"; teardown

# 4. 変更なし → 開かない
setup
run HERDR_ENV=1
check "変更なし" "開かない"; teardown

# 5. 既に hunk が起動中 → 開かない
setup; echo "変更" >> a.txt
run HERDR_ENV=1 SESSIONS_JSON='{"sessions": [{"id":"x"}]}'
check "既に起動中" "開かない"; teardown

# 6. 未追跡ファイルだけの変更 → 開く（新規ファイルも変更）
setup; echo "新規" > new.txt
run HERDR_ENV=1
check "未追跡ファイルのみ" "開く"; teardown

# 7. hunk コマンドが無い → 開かない・落ちない
setup; echo "変更" >> a.txt; rm -f "$STUB/hunk"
# PATH を絞って本物の hunk（/opt/homebrew/bin）を拾わせない
env PATH="$STUB:/usr/bin:/bin" CLAUDE_PROJECT_DIR="$SANDBOX" STUB_INVOKED="$STUB_INVOKED" \
    HERDR_ENV=1 bash "$HOOK" >/dev/null 2>&1
check "hunk未導入" "開かない"; teardown

# 8. git 管理外 → 落ちない
SANDBOX="$(mktemp -d)"; STUB="$(mktemp -d)"
export STUB_INVOKED="$SANDBOX/invoked"
printf '#!/bin/bash\nexit 0\n' > "$STUB/herdr"; cp "$STUB/herdr" "$STUB/hunk"; chmod +x "$STUB"/*
if env PATH="$STUB:$PATH" CLAUDE_PROJECT_DIR="$SANDBOX" HERDR_ENV=1 bash "$HOOK" >/dev/null 2>&1; then
  echo "  ✅ git管理外 → 落ちずに終了"; PASS=$((PASS+1))
else
  echo "  ❌ git管理外 → 異常終了"; FAIL=$((FAIL+1))
fi
rm -rf "$SANDBOX" "$STUB"

echo
echo "結果: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
