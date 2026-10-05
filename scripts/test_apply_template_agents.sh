#!/usr/bin/env bash
# apply_template.sh の --codex / --cursor / --antigravity の検証スクリプト。
# 「作るべきもの」と「触ってはいけないもの」の両方で確かめる（全件通る壊れ方は気づけないため）。
# 複数の AI を同時に使う人のために、組み合わせても1つずつ流しても同じものができることを確かめる（人間の決定）。
# 使い捨てのディレクトリに適用して試すので、このリポジトリは汚さない。1回の適用でフックの検証も流れるため、数分かかる。
# macOS 標準の bash 3.2 でも確かめるときは TEST_BASH=/bin/bash を付けて流す（bash のバージョンで結果が変わる書き方を拾うため）
set -uo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APPLY="$SCRIPT_DIR/apply_template.sh"
TEMPLATE_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TEST_BASH="${TEST_BASH:-bash}"
echo "apply_template.sh を流す bash: $("$TEST_BASH" -c 'echo $BASH_VERSION')"
PASS=0; FAIL=0
# 空白を含むパスでも動くことを兼ねて確かめる
WORK="$(mktemp -d)/work dir"; mkdir -p "$WORK"
trap 'rm -rf "$(dirname "$WORK")"' EXIT

N_SKILLS="$(ls -d "$TEMPLATE_ROOT"/.claude/skills/*/ | wc -l | tr -d ' ')"
N_RULES="$(ls "$TEMPLATE_ROOT"/.claude/rules/*.md | wc -l | tr -d ' ')"

ok()   { PASS=$((PASS + 1)); echo "  PASS  $1"; }
ng()   { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; }
check() { if eval "$2"; then ok "$1"; else ng "$1"; fi; }

# $1: 反映先、残り: apply_template.sh のオプション。出力を $OUT に入れ、終了コードを返す
run() {
  local t="$1"; shift
  OUT="$("$TEST_BASH" "$APPLY" --target "$t" --no-backup "$@" 2>&1)"; RC=$?
  return "$RC"
}

# ほかのエージェント向けの生成物の指紋（種類・リンク先・中身・権限）。比べて同じなら同じものができている
fingerprint() {
  local t="$1" p
  ( cd "$t" && find AGENTS.md .agents .cursor 2>/dev/null | LC_ALL=C sort | while IFS= read -r p; do
      if [ -L "$p" ]; then echo "L $p -> $(readlink "$p")"
      elif [ -f "$p" ]; then echo "F $p $(ls -l "$p" | cut -c1-10) $(cksum < "$p")"
      else echo "D $p"; fi
    done )
}

# 複製元（オプションなしで一度適用したもの）。ケースごとにこれを複製して使う
BASE="$WORK/base"; mkdir -p "$BASE"
run "$BASE" || { echo "複製元への適用に失敗しました"; echo "$OUT" | tail -n 20; exit 1; }
fresh() { local d="$WORK/$1"; rsync -a "$BASE/" "$d/"; echo "$d"; }

echo "== 新規・3つ一緒"
ALL="$(fresh all)"
run "$ALL" --codex --cursor --antigravity; check "終了コード0" "[ $? -eq 0 ]"
check "AGENTS.md は CLAUDE.md へのリンク" '[ -L "$ALL/AGENTS.md" ] && [ "$(readlink "$ALL/AGENTS.md")" = CLAUDE.md ]'
check ".agents/skills のリンクがスキルの数だけある" '[ "$(find "$ALL/.agents/skills" -mindepth 1 -maxdepth 1 -type l | wc -l | tr -d " ")" = "$N_SKILLS" ]'
check ".agents/skills のリンクがすべて SKILL.md に届く" '! for l in "$ALL"/.agents/skills/*; do [ -f "$l/SKILL.md" ] || echo x; done | grep -q x'
check ".cursor/rules が rules の数だけある" '[ "$(ls "$ALL"/.cursor/rules/ai-template-*.mdc | wc -l | tr -d " ")" = "$N_RULES" ]'
check ".agents/rules が rules の数だけある" '[ "$(ls "$ALL"/.agents/rules/ai-template-*.md | wc -l | tr -d " ")" = "$N_RULES" ]'
check "Cursor の写しは alwaysApply: true で、5行目が印" '[ "$(sed -n 3p "$ALL/.cursor/rules/ai-template-git.mdc")" = "alwaysApply: true" ] && sed -n 5p "$ALL/.cursor/rules/ai-template-git.mdc" | grep -q "^<!-- 生成物: scripts/apply_template.sh"'
check "Antigravity の写しは model_decision で、5行目が印" '[ "$(sed -n 2p "$ALL/.agents/rules/ai-template-git.md")" = "trigger: model_decision" ] && sed -n 5p "$ALL/.agents/rules/ai-template-git.md" | grep -q "^<!-- 生成物: scripts/apply_template.sh"'
check "写しの本文は元の rule そのもの" 'tail -n +7 "$ALL/.cursor/rules/ai-template-git.mdc" | cmp -s - "$ALL/.claude/rules/git.md"'
check "CLAUDE.md を .agents/rules に入れない" '! ls "$ALL"/.agents/rules | grep -qv "^ai-template-"'
check "写しの権限は 644" '[ -n "$(find "$ALL/.cursor/rules/ai-template-git.mdc" -perm 644)" ]'
FP_ALL="$(fingerprint "$ALL")"
# 指紋が空だと、比べる両方が空で一致して「同じ」と通ってしまう。中身があることを先に確かめる
check "（前提）指紋に生成物がすべて入っている" '[ "$(printf "%s\n" "$FP_ALL" | grep -c "^[LF] ")" -ge $((1 + N_SKILLS + 2 * N_RULES)) ]'

echo "== 入れ方で結果が変わらない"
SEQ="$(fresh seq)"
run "$SEQ" --codex; run "$SEQ" --cursor; run "$SEQ" --antigravity
check "codex → cursor → antigravity と1つずつ流しても同じ" '[ "$(fingerprint "$SEQ")" = "$FP_ALL" ]'
REV="$(fresh rev)"
run "$REV" --antigravity; run "$REV" --cursor --codex
check "逆の順番で流しても同じ" '[ "$(fingerprint "$REV")" = "$FP_ALL" ]'
run "$ALL" --codex --cursor --antigravity
check "二度流しても変わらない" '[ "$(fingerprint "$ALL")" = "$FP_ALL" ]'
check "二度目は作るもの0" 'echo "$OUT" | grep -q "作る 0 本" && [ "$(echo "$OUT" | grep -c "作る 0 件")" = 2 ]'

echo "== 選んだものだけ作る"
CUR="$(fresh cursor-only)"; run "$CUR" --cursor
check "--cursor だけなら .agents を作らない" '[ ! -e "$CUR/.agents" ] && [ -L "$CUR/AGENTS.md" ] && [ -d "$CUR/.cursor/rules" ]'
COD="$(fresh codex-only)"; run "$COD" --codex
check "--codex だけなら rules の写しを作らない" '[ ! -e "$COD/.cursor" ] && [ ! -e "$COD/.agents/rules" ] && [ -d "$COD/.agents/skills" ]'
NOS="$(fresh no-skills)"; run "$NOS" --no-skills --codex
check "--no-skills では作らず、そう表示する" '[ ! -e "$NOS/AGENTS.md" ] && [ ! -e "$NOS/.agents" ] && echo "$OUT" | grep -q "no-skills のため作りません"'

echo "== 手で置いたものに触らない"
HW="$(fresh handwritten)"; printf '手書き\n' > "$HW/AGENTS.md"
mkdir -p "$HW/.cursor/rules"; printf -- '---\nalwaysApply: true\n---\n手書き\n' > "$HW/.cursor/rules/ai-template-git.mdc"
mkdir -p "$HW/.cursor/rules"; printf -- '手書き\n' > "$HW/.cursor/rules/ai-template-zz-gone.mdc"
run "$HW" --cursor
check "手書きの AGENTS.md はそのまま" '[ ! -L "$HW/AGENTS.md" ] && [ "$(cat "$HW/AGENTS.md")" = 手書き ] && echo "$OUT" | grep -q "SKIP AGENTS.md"'
check "印の無い同名の写しはそのまま" 'grep -q 手書き "$HW/.cursor/rules/ai-template-git.mdc" && echo "$OUT" | grep -q "SKIP .cursor/rules/ai-template-git.mdc"'
check "元の rule が無くても、印の無いものは外さない" '[ "$RC" = 0 ] && [ -f "$HW/.cursor/rules/ai-template-zz-gone.mdc" ] && echo "$OUT" | grep -q "^  .cursor/rules: 作る .*外す 0 件"'
OL="$(fresh other-link)"; ln -s README.md "$OL/AGENTS.md"; run "$OL" --codex
check "別の場所を指す AGENTS.md のリンクはそのまま" '[ "$(readlink "$OL/AGENTS.md")" = README.md ]'
FL="$(fresh foreign-link)"; mkdir -p "$FL/.agents/skills"; ln -s /nonexistent/zz "$FL/.agents/skills/zz-foreign"; ln -s ../../elsewhere/basic-review "$FL/.agents/skills/basic-review"
run "$FL" --codex
check "よそのリンク（リンク切れも）は外さない" '[ "$RC" = 0 ] && echo "$OUT" | grep -q "^  .agents/skills: 作る .*外す 0 本" && [ -L "$FL/.agents/skills/zz-foreign" ] && [ "$(readlink "$FL/.agents/skills/basic-review")" = ../../elsewhere/basic-review ]'

echo "== リンク越しに配布先の外へ書かない"
OUTSIDE="$WORK/outside"; mkdir -p "$OUTSIDE"
LA="$(fresh link-agents)"; ln -s "$OUTSIDE" "$LA/.agents"; run "$LA" --antigravity
check ".agents がリンクなら外へ書かない" '[ "$RC" = 0 ] && [ -z "$(ls -A "$OUTSIDE")" ] && echo "$OUT" | grep -q "リンクになっているため作りません"'
LC="$(fresh link-cursor)"; mkdir -p "$LC/.cursor"; ln -s "$OUTSIDE" "$LC/.cursor/rules"; run "$LC" --cursor
check ".cursor/rules がリンクなら外へ書かない" '[ "$RC" = 0 ] && [ -z "$(ls -A "$OUTSIDE")" ] && echo "$OUT" | grep -q "途中のディレクトリがリンクになっているため作りません"'

LO="$(fresh link-out)"; mkdir -p "$LO/.cursor/rules"
ln -s "$OUTSIDE/new.mdc" "$LO/.cursor/rules/ai-template-git.mdc"
printf -- '---\na\nb\n---\n<!-- 生成物: scripts/apply_template.sh 外のファイル\n' > "$WORK/outside-marked.mdc"; cp "$WORK/outside-marked.mdc" "$WORK/outside-marked.orig"
ln -s "$WORK/outside-marked.mdc" "$LO/.cursor/rules/ai-template-tool-usage.mdc"
run "$LO" --cursor
check "写し先がリンク切れでも、外にファイルを作らない" '[ -z "$(ls -A "$OUTSIDE")" ] && echo "$OUT" | grep -q "SKIP .cursor/rules/ai-template-git.mdc（リンク"'
check "写し先が外の印つきファイルを指すリンクでも、上書きしない" 'cmp -s "$WORK/outside-marked.mdc" "$WORK/outside-marked.orig"'

echo "== 写しのずれを、流すたびに見つける"
DR="$(fresh drift)"; run "$DR" --cursor --antigravity
echo "追記した行" >> "$DR/.claude/rules/git.md"
run "$DR"
check "選んでいなくても、ずれを知らせる" 'echo "$OUT" | grep -q "⚠️ .cursor/rules: .*中身が違う・元が無い 1 件" && echo "$OUT" | grep -q "⚠️ .agents/rules: .*中身が違う・元が無い 1 件"'
check "選んでいないときは書き換えない" '[ -f "$DR/.cursor/rules/ai-template-git.mdc" ] && ! grep -q 追記した行 "$DR/.cursor/rules/ai-template-git.mdc"'
run "$DR" --cursor
check "選べば作り直す（選ばなかった方はずれたまま知らせる）" 'grep -q 追記した行 "$DR/.cursor/rules/ai-template-git.mdc" && ! grep -q 追記した行 "$DR/.agents/rules/ai-template-git.md" && echo "$OUT" | grep -q "⚠️ .agents/rules"'

printf '# 足した決まり\n' > "$DR/.claude/rules/zz-added.md"
run "$DR"
check "選んでいなくても、写しの無い rule を知らせる" 'echo "$OUT" | grep -q "⚠️ .cursor/rules: .*写しの無い rule 1 件"'

echo "== rules の形"
SUB="$(fresh subdir)"; mkdir -p "$SUB/.claude/rules/front"; printf '# 画面の決まり\n本文\n' > "$SUB/.claude/rules/front/ui.md"
printf -- '---\npaths:\n  - "src/**/*.ts"\n---\n# TS の決まり\n' > "$SUB/.claude/rules/zz-paths.md"
printf '本文だけ\n```\n# コードの中の見出し\n```\n# 本当の見出し\n' > "$SUB/.claude/rules/zz-fence.md"
run "$SUB" --cursor --antigravity
check "サブディレクトリの rule も写す" '[ -f "$SUB/.cursor/rules/ai-template-front--ui.mdc" ] && [ -f "$SUB/.agents/rules/ai-template-front--ui.md" ]'
check "二度流してもサブディレクトリの写しを外さない" 'run "$SUB" --cursor; [ -f "$SUB/.cursor/rules/ai-template-front--ui.mdc" ]'
check "frontmatter のある rule は写さず、そう表示する" '[ ! -e "$SUB/.cursor/rules/ai-template-zz-paths.mdc" ] && echo "$OUT" | grep -q "zz-paths.mdc（元の .claude/rules/zz-paths.md に frontmatter"'
SH="$WORK/shared-rules"; mkdir -p "$SH"; printf '# 共有の決まり\n' > "$SH/common.md"; ln -s "$SH" "$SUB/.claude/rules/shared"
printf -- '---\r\npaths:\r\n  - "src/**"\r\n---\r\n# CRLF\r\n' > "$SUB/.claude/rules/zz-crlf.md"
printf -- '\xef\xbb\xbf---\npaths:\n  - "src/**"\n---\n# BOM\n' > "$SUB/.claude/rules/zz-bom.md"
run "$SUB" --cursor
check "リンクのディレクトリの中の rule も写す" '[ -f "$SUB/.cursor/rules/ai-template-shared--common.mdc" ]'
check "CRLF・BOM 付きの frontmatter も見分けて写さない" '[ ! -e "$SUB/.cursor/rules/ai-template-zz-crlf.mdc" ] && [ ! -e "$SUB/.cursor/rules/ai-template-zz-bom.mdc" ]'
printf -- '---\n# 区切りで始まる\n本文\n' > "$SUB/.claude/rules/zz-hr.md"; printf '# CRLF の見出し\r\n本文\r\n' > "$SUB/.claude/rules/zz-crtitle.md"
run "$SUB" --cursor
check "閉じの --- が無ければ frontmatter とみなさず写す" '[ -f "$SUB/.cursor/rules/ai-template-zz-hr.mdc" ]'
CR="$(printf '\r')"
check "CRLF の見出しから description に CR を入れない" 'sed -n 2p "$SUB/.cursor/rules/ai-template-zz-crtitle.mdc" | grep -q "CRLF の見出し（" && ! sed -n 2p "$SUB/.cursor/rules/ai-template-zz-crtitle.mdc" | grep -qF "$CR"'
check "コードブロックの中の見出しを拾わない" 'grep -q "^description: .本当の見出し" "$SUB/.cursor/rules/ai-template-zz-fence.mdc"'
RO="$(fresh read-only)"; run "$RO" --cursor; printf '# 足した\n' > "$RO/.claude/rules/zz-ro.md"; chmod 555 "$RO/.cursor/rules"
run "$RO" --cursor; rc=$?; chmod 755 "$RO/.cursor/rules"
check "書けなければ「失敗:」と出し、終了コード4" '[ "$rc" = 4 ] && echo "$OUT" | grep -q "失敗: .cursor/rules/ai-template-zz-ro.mdc"'

echo "== 元が消えたものを外す"
GN="$(fresh gone)"; printf '# 手元の決まり\n本文\n' > "$GN/.claude/rules/zz-local.md"
mkdir -p "$GN/.claude/skills/zz-local"; printf -- '---\nname: zz-local\ndescription: 手元のスキル\n---\n' > "$GN/.claude/skills/zz-local/SKILL.md"
run "$GN" --codex --cursor
check "（前提）手元の rule の写しとスキルのリンクができている" '[ -f "$GN/.cursor/rules/ai-template-zz-local.mdc" ] && [ -L "$GN/.agents/skills/zz-local" ]'
rm "$GN/.claude/rules/zz-local.md"; rm -r "$GN/.claude/skills/zz-local"
run "$GN"
check "選んでいなくても、リンク切れを知らせる" 'echo "$OUT" | grep -q "⚠️ .agents/skills"'
run "$GN" --codex --cursor
check "元の rule が無い生成物を外す" '[ ! -e "$GN/.cursor/rules/ai-template-zz-local.mdc" ]'
check "元のスキルが無いリンクを外す" '[ ! -L "$GN/.agents/skills/zz-local" ]'
NS="$(fresh new-skill)"; run "$NS" --codex
mkdir -p "$NS/.claude/skills/zz-new"; printf -- '---\nname: zz-new\ndescription: 足したスキル\n---\n' > "$NS/.claude/skills/zz-new/SKILL.md"
run "$NS"
check "足したスキルにリンクが無いことを知らせる" 'echo "$OUT" | grep -q "⚠️ .agents/skills"'

echo "== 名前の大文字・小文字だけを変えたとき"
RN="$(fresh rename-case)"; printf '# Foo\n' > "$RN/.claude/rules/Foo.md"
mkdir -p "$RN/.claude/skills/Zed"; printf -- '---\nname: Zed\ndescription: 確認用\n---\n' > "$RN/.claude/skills/Zed/SKILL.md"
run "$RN" --codex --cursor
mv "$RN/.claude/rules/Foo.md" "$RN/x.md"; mv "$RN/x.md" "$RN/.claude/rules/foo.md"
mv "$RN/.claude/skills/Zed" "$RN/zed-tmp"; mv "$RN/zed-tmp" "$RN/.claude/skills/zed"
run "$RN" --codex --cursor
check "1回流せば、新しい名前の写しとリンクができている" '[ "$RC" = 0 ] && ls "$RN/.cursor/rules" | grep -qx "ai-template-foo.mdc" && ! ls "$RN/.cursor/rules" | grep -qx "ai-template-Foo.mdc" && [ "$(readlink "$RN/.agents/skills/zed")" = ../../.claude/skills/zed ] && ls "$RN/.agents/skills" | grep -qx zed'
FP_RN="$(fingerprint "$RN")"; run "$RN" --codex --cursor
check "もう一度流しても変わらない" '[ "$(fingerprint "$RN")" = "$FP_RN" ]'

echo "== dry-run"
DRY="$WORK/dry"; mkdir -p "$DRY"
run "$DRY" --dry-run --codex --cursor --antigravity
check "dry-run では何も書かない" '[ -z "$(ls -A "$DRY")" ]'
DRY_SUM="$(echo "$OUT" | grep -E "^  (AGENTS.md|\.agents/skills|\.cursor/rules|\.agents/rules): " | sed -e 's/。dry-run のため書いていません$//' -e 's/作ります$/作りました/')"
REAL="$(fresh dry-vs-real)"; run "$REAL" --codex --cursor --antigravity
REAL_SUM="$(echo "$OUT" | grep -E "^  (AGENTS.md|\.agents/skills|\.cursor/rules|\.agents/rules): ")"
check "dry-run の数え方が本番と一致する" '[ -n "$DRY_SUM" ] && [ "$DRY_SUM" = "$REAL_SUM" ]'
run "$DRY" --dry-run --codex --cursor --antigravity
check "dry-run でも、反映後のスキルの数で数える" 'echo "$OUT" | grep -q "作る ${N_SKILLS} 本"'
check "dry-run でも、反映後の rules の数で数える" '[ "$(echo "$OUT" | grep -c "作る ${N_RULES} 件")" = 2 ]'
INST="$(fresh dry-installed)"; run "$INST" --cursor --antigravity; echo "追記" >> "$INST/.claude/rules/git.md"; FP_INST="$(fingerprint "$INST")"
run "$INST" --dry-run --codex --cursor --antigravity
check "入っている配布先への dry-run は何も変えず、作り直す数を数える" '[ "$(fingerprint "$INST")" = "$FP_INST" ] && echo "$OUT" | grep -q ".cursor/rules: 作る 0 件・作り直す 1 件"'
run "$INST" --dry-run --force --cursor
check "force の dry-run では、テンプレートの rule に戻る分も数える" 'echo "$OUT" | grep -q ".cursor/rules: 作る 0 件・作り直す 0 件・そのまま ${N_RULES} 件"'
SY="$(fresh dry-sync)"; printf '# 手元\n' > "$SY/.claude/rules/zz-local.md"
run "$SY" --dry-run --sync --cursor
check "dry-run の sync では、消えるはずの rule を数えない" 'echo "$OUT" | grep -q ".cursor/rules: 作る ${N_RULES} 件"'

echo "== 説明文と上限"
ES="$(fresh escape)"; printf "# It's a \\\\path \"q\": x\n本文\n" > "$ES/.claude/rules/zz-esc.md"
head -c 25000 /dev/zero | tr '\0' 'a' > "$ES/.claude/rules/zz-big.md"
run "$ES" --cursor --antigravity
if command -v ruby >/dev/null 2>&1; then
  # 見出しが元のまま description に入っているかを、YAML のパーサで読んで比べる
  if EXP="It's a \\path \"q\": x（.claude/rules/zz-esc.md）" ruby -ryaml -e 'd = YAML.safe_load(File.read(ARGV[0]).split(/^---$/)[1]); exit(d["description"] == ENV["EXP"] ? 0 : 1)' "$ES/.cursor/rules/ai-template-zz-esc.mdc"; then
    ok "引用符・\\・コロンを含む見出しが YAML として元のまま読める"
  else
    ng "引用符・\\・コロンを含む見出しが YAML として元のまま読める"
  fi
else
  echo "  SKIP  YAML のパーサが無いため、説明文の読み取りは確かめていない"
fi
check "Antigravity の1ファイル上限を超えたら知らせる" 'echo "$OUT" | grep -q "ai-template-zz-big.md が Antigravity の1ファイルの上限"'
run "$ES" --antigravity
check "上限の警告は、中身が同じ2回目にも出る" 'echo "$OUT" | grep -q "ai-template-zz-big.md が Antigravity の1ファイルの上限"'
run "$ES"
check "上限の警告は、選んでいないときにも出る" 'echo "$OUT" | grep -q "ai-template-zz-big.md が Antigravity の1ファイルの上限"'

echo "== 写せない rule"
FM="$(fresh fm-later)"; run "$FM" --cursor
{ printf -- '---\npaths:\n  - "src/**"\n---\n'; cat "$FM/.claude/rules/git.md"; } > "$FM/git.tmp" && mv "$FM/git.tmp" "$FM/.claude/rules/git.md"
run "$FM"
check "写したあとで frontmatter が付いたら、ずれとして知らせる" 'echo "$OUT" | grep -q "⚠️ .cursor/rules: .*中身が違う・元が無い 1 件"'
run "$FM" --cursor
check "選べば、frontmatter の付いた rule の古い写しを外す" '[ ! -e "$FM/.cursor/rules/ai-template-git.mdc" ] && echo "$OUT" | grep -q "写せなくなった rule の古い生成物を外します"'
FB="$(fresh fm-backup)"; run "$FB" --cursor; echo "外す前の手直し" >> "$FB/.cursor/rules/ai-template-git.mdc"
{ printf -- '---\npaths:\n  - "src/**"\n---\n'; cat "$FB/.claude/rules/git.md"; } > "$FB/git.tmp" && mv "$FB/git.tmp" "$FB/.claude/rules/git.md"
OUT="$("$TEST_BASH" "$APPLY" --target "$FB" --cursor 2>&1)"
check "frontmatter で外す前にも退避する" '[ ! -e "$FB/.cursor/rules/ai-template-git.mdc" ] && grep -rqs "外す前の手直し" "$FB/.ai-template-backup"'
SN="$(fresh sync-real)"; printf '# 手元\n' > "$SN/.claude/rules/zz-local.md"; run "$SN" --cursor
run "$SN" --sync --cursor
check "sync の本番では、消えた rule の写しも外す" '[ "$RC" = 0 ] && [ ! -e "$SN/.claude/rules/zz-local.md" ] && [ ! -e "$SN/.cursor/rules/ai-template-zz-local.mdc" ] && [ "$(ls "$SN"/.cursor/rules/ai-template-*.mdc | wc -l | tr -d " ")" = "$N_RULES" ]'
DG="$(fresh dangling-rule)"; ln -s /nonexistent/zz.md "$DG/.claude/rules/zz-dangling.md"
run "$DG" --cursor; rc=$?
OUT_REAL="$OUT"
DGD="$(fresh dangling-dry)"; ln -s /nonexistent/zz.md "$DGD/.claude/rules/zz-dangling.md"
run "$DGD" --dry-run --cursor
check "dry-run でもリンク切れの rule を「失敗:」と知らせる" 'echo "$OUT" | grep -q "失敗: .claude/rules/zz-dangling.md を読めない"'
OUT="$OUT_REAL"
check "リンク切れの rule は写さず、「失敗:」と終了コード4" '[ "$rc" = 4 ] && [ ! -e "$DG/.cursor/rules/ai-template-zz-dangling.mdc" ] && echo "$OUT" | grep -q "失敗: .claude/rules/zz-dangling.md を読めない"'
DP="$(fresh dup-name)"; mkdir -p "$DP/.claude/rules/front"; printf '# A\n' > "$DP/.claude/rules/front/ui.md"; printf '# B\n' > "$DP/.claude/rules/front--ui.md"
run "$DP" --cursor; rc=$?
check "写し先の名前がぶつかれば、どちらも作らず終了コード4" '[ "$rc" = 4 ] && [ ! -e "$DP/.cursor/rules/ai-template-front--ui.mdc" ] && echo "$OUT" | grep -q "失敗: .cursor/rules/ai-template-front--ui.mdc は、別の rule と"'
MID="$(fresh mark-mid)"; mkdir -p "$MID/.cursor/rules"; printf -- '---\na\nb\n---\nx <!-- 生成物: scripts/apply_template.sh\n' > "$MID/.cursor/rules/ai-template-git.mdc"
run "$MID" --cursor
check "印が5行目の先頭に無ければ手書きとして扱う" 'grep -q "^x <!--" "$MID/.cursor/rules/ai-template-git.mdc" && echo "$OUT" | grep -q "SKIP .cursor/rules/ai-template-git.mdc（生成物の印が無い"'
CI="$(fresh case-dup)"; mkdir -p "$CI/.claude/rules/front"; printf '# A\n' > "$CI/.claude/rules/front/UI.md"; printf '# B\n' > "$CI/.claude/rules/front--ui.md"
run "$CI" --cursor; rc=$?
check "大文字・小文字だけ違う写し先もぶつかりとして扱う" '[ "$rc" = 4 ] && [ -z "$(ls "$CI/.cursor/rules" | grep -i "front--ui")" ]'
if [ "$(id -u)" = 0 ]; then
  echo "  SKIP  root では読めないディレクトリを作れないため、読み切れないときのケースは確かめていない"
else
UR="$(fresh unreadable-dir)"; mkdir -p "$UR/.claude/rules/private"; printf '# 秘密\n' > "$UR/.claude/rules/private/a.md"
run "$UR" --cursor --antigravity
check "（前提）サブディレクトリの写しができている" '[ -f "$UR/.cursor/rules/ai-template-private--a.mdc" ]'
chmod 000 "$UR/.claude/rules/private"; run "$UR" --cursor; rc=$?; chmod 755 "$UR/.claude/rules/private"
check "rules を読み切れなければ写しに触らず、終了コード4" '[ "$rc" = 4 ] && [ -f "$UR/.cursor/rules/ai-template-private--a.mdc" ] && echo "$OUT" | grep -q "失敗: .claude/rules/ を読み切れないため、.cursor/rules には触りません" && ! echo "$OUT" | grep -q "rules: 今回は選んでいません"'
fi
HL="$(fresh hardlink)"; run "$HL" --cursor; cp "$HL/.cursor/rules/ai-template-git.mdc" "$WORK/hl-outside.mdc"; cp "$WORK/hl-outside.mdc" "$WORK/hl-outside.orig"
rm "$HL/.cursor/rules/ai-template-git.mdc"; ln "$WORK/hl-outside.mdc" "$HL/.cursor/rules/ai-template-git.mdc"; echo "追記" >> "$HL/.claude/rules/git.md"
run "$HL" --cursor
check "写し先がハードリンクでも、外のファイルを書き換えない" 'cmp -s "$WORK/hl-outside.mdc" "$WORK/hl-outside.orig" && grep -q "^追記" "$HL/.cursor/rules/ai-template-git.mdc"'
CX="$(fresh codex-limit)"; run "$CX" --codex; head -c 33000 /dev/zero | tr '\0' 'a' >> "$CX/CLAUDE.md"
run "$CX"
check "選んでいなくても、Codex の上限を超えたら知らせる" 'echo "$OUT" | grep -q "Codex の既定の読み込み上限"'
BK="$(fresh backup)"; run "$BK" --cursor; echo "手で直した行" >> "$BK/.cursor/rules/ai-template-git.mdc"
OUT="$("$TEST_BASH" "$APPLY" --target "$BK" --cursor 2>&1)"
check "作り直す前に、手で直した写しを退避する" 'grep -rqs "手で直した行" "$BK/.ai-template-backup" && ! grep -q "手で直した行" "$BK/.cursor/rules/ai-template-git.mdc"'
BR="$(fresh backup-remove)"; printf '# 消す決まり\n' > "$BR/.claude/rules/zz-gone.md"; run "$BR" --cursor
echo "外す前に直した行" >> "$BR/.cursor/rules/ai-template-zz-gone.mdc"; rm "$BR/.claude/rules/zz-gone.md"
OUT="$("$TEST_BASH" "$APPLY" --target "$BR" --cursor 2>&1)"
check "外す前にも、手で直した写しを退避する" '[ ! -e "$BR/.cursor/rules/ai-template-zz-gone.mdc" ] && grep -rqs "外す前に直した行" "$BR/.ai-template-backup"'
DU="$(fresh dangling-unselected)"; run "$DU" --cursor; ln -s /nonexistent/zz.md "$DU/.claude/rules/zz-dangling.md"
run "$DU"
check "選んでいなくても、写せない rule をずれとして知らせる" 'echo "$OUT" | grep -q "⚠️ .cursor/rules: .*写しの無い rule 1 件"'
AF="$(fresh agents-file)"; printf 'ファイル\n' > "$AF/.agents"
run "$AF" --antigravity; rc=$?
check ".agents が普通のファイルなら「失敗:」を1行ずつで知らせ、終了コード4" '[ "$rc" = 4 ] && [ "$(echo "$OUT" | grep -c "^  失敗: ")" = 2 ] && [ "$(cat "$AF/.agents")" = ファイル ]'

echo "----"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
