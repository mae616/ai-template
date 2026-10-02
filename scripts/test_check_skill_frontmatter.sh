#!/usr/bin/env bash
# check_skill_frontmatter.sh の検証スクリプト。
# 「通すべきもの」と「外すべきもの」の両方で動かす（全件通る壊れ方は気づけないため）。
# 使い捨てのディレクトリを作って試すので、このリポジトリは汚さない。
set -uo pipefail
CHECK="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/check_skill_frontmatter.sh"
PASS=0; FAIL=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# $1: 期待（0=通過 / 1=外れ）、$2: ケース名、$3: ディレクトリ名、$4: SKILL.md の中身
expect() {
  local want="$1" label="$2" dir="$3" body="$4" d rc
  d="$WORK/$MODE-$label"; mkdir -p "$d/$dir"
  printf '%s\n' "$body" > "$d/$dir/SKILL.md"
  CHECK_SKILL_NO_PARSER="$NO_PARSER" bash "$CHECK" "$d" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq "$want" ]; then PASS=$((PASS + 1)); echo "  PASS  [$MODE] $label"
  else FAIL=$((FAIL + 1)); echo "  FAIL  [$MODE] $label (期待=$want 実際=$rc)"; fi
}

# 共通のケース。パーサの経路と簡易の経路の両方で流す
run_common() {
  expect 0 "正しい"           good-skill $'---\nname: good-skill\ndescription: 何をするか。いつ使うか。\n---\n本文'
  expect 0 "本文にname行がある" body-name  $'---\nname: body-name\ndescription: 説明\n---\nname: 本文の行'
  expect 1 "nameが無い"        no-name    $'---\ndescription: 説明\n---\n本文'
  expect 1 "大文字"            Upper      $'---\nname: Upper\ndescription: 説明\n---'
  expect 1 "連続ハイフン"      a--b       $'---\nname: a--b\ndescription: 説明\n---'
  expect 1 "ディレクトリと違う" dir-a      $'---\nname: dir-b\ndescription: 説明\n---'
  expect 1 "descriptionが無い" no-desc    $'---\nname: no-desc\n---'
  # 複数行の書き方は正しい YAML。パーサの経路では通し、長さを測れない簡易の経路では外す
  expect "$([ "$MODE" = parser ] && echo 0 || echo 1)" "複数行のdescription" multi    $'---\nname: multi\ndescription: >\n  説明\n---'
  expect 1 "閉じていない"      unclosed   $'---\nname: unclosed\ndescription: 説明'
  expect 1 "frontmatterが無い" none       $'# 見出しだけ'
  expect 1 "閉じていないクォート" unq      $'---\nname: unq\ndescription: "閉じていない\n---'
  expect 1 "クォート無しのコロン" colon    $'---\nname: colon\ndescription: foo: bar\n---'
  expect 1 "空の文字列"        empty      $'---\nname: empty\ndescription: \'\'\n---'
  expect 1 "先頭のハイフン"    -lead      $'---\nname: -lead\ndescription: 説明\n---'
  expect 1 "末尾のハイフン"    trail-     $'---\nname: trail-\ndescription: 説明\n---'
  N65="$(printf 'a%.0s' $(seq 1 65))"
  expect 1 "nameが65文字"      "$N65"     "---"$'\n'"name: $N65"$'\n'"description: 説明"$'\n'"---"
  N64="$(printf 'a%.0s' $(seq 1 64))"
  expect 0 "nameが64文字"      "$N64"     "---"$'\n'"name: $N64"$'\n'"description: 説明"$'\n'"---"
  D1024="$(printf 'あ%.0s' $(seq 1 1024))"
  expect 0 "descriptionが日本語1024文字" d1024 "---"$'\n'"name: d1024"$'\n'"description: $D1024"$'\n'"---"
  expect 1 "descriptionが日本語1025文字" d1025 "---"$'\n'"name: d1025"$'\n'"description: ${D1024}あ"$'\n'"---"
  expect 0 "クォートで囲んだ説明" quoted    $'---\nname: quoted\ndescription: "何を: いつ"\n---'

  # スキルが1本も無いディレクトリは外れ（全件通る壊れ方を防ぐ）
  mkdir -p "$WORK/$MODE-empty-dir"
  if CHECK_SKILL_NO_PARSER="$NO_PARSER" bash "$CHECK" "$WORK/$MODE-empty-dir" >/dev/null 2>&1; then FAIL=$((FAIL + 1)); echo "  FAIL  [$MODE] スキルが0本"; else PASS=$((PASS + 1)); echo "  PASS  [$MODE] スキルが0本"; fi
}

MODE=simple; NO_PARSER=1; run_common
if command -v ruby >/dev/null 2>&1 && ruby -ryaml -e 'YAML.safe_load("a: b")' >/dev/null 2>&1; then
  MODE=parser; NO_PARSER=""; run_common
  # パーサの経路だけで外せるもの（簡易の経路では見えない、YAML として読めない書き方）
  expect 1 "値がハイフンで始まる"   dash    $'---\nname: dash\ndescription: - foo\n---'
  expect 1 "値が?で始まる"          qmark   $'---\nname: qmark\ndescription: ? foo\n---'
  expect 1 "値の末尾がコロン"       tcolon  $'---\nname: tcolon\ndescription: foo:\n---'
  expect 1 "コロンの後がタブ"       tab     $'---\nname: tab\ndescription: foo:\tbar\n---'
  expect 1 "エスケープしたクォートで終わる" escq $'---\nname: escq\ndescription: "abc\\"\n---'
  expect 1 "不正なエスケープ"       badesc  $'---\nname: badesc\ndescription: "\\q"\n---'
  expect 1 "コロンの後に空白が無い" nosp    $'---\nname: nosp\ndescription:foo\n---'
  expect 1 "ほかのキーが壊れている" other   $'---\nname: other\ndescription: 説明\nuser-invocable: [true\n---'
  expect 1 "インデントが壊れている" indent  $'---\nname: indent\n  description: 説明\n---'
  expect 1 "空白だけの説明"         blank   $'---\nname: blank\ndescription: "   "\n---'
else
  echo "  SKIP  YAML のパーサが無いため、パーサの経路は確かめていない"
fi

echo "----"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
