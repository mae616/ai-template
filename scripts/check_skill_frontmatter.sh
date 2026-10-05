#!/usr/bin/env bash
# スキルの frontmatter が Agent Skills 仕様の必須項目を満たしているかを数える。
# 決まり（出典: https://agentskills.io/specification）:
#   - name: 必須。小文字・数字・ハイフンのみ、64文字まで、先頭末尾のハイフンと連続ハイフンは不可、ディレクトリ名と一致
#   - description: 必須。空白だけでない、1024文字まで
#   - YAML のパーサ（ruby）があれば frontmatter 全体をパーサで読む。無ければ下の簡易判定で値の書き方を絞る
#     （閉じたクォート／「: 」「 #」を含まない素の文字列。複数行の書き方は長さを測れないので外れ）
# 「name は必須」と書くだけでは、次に足されるスキルで守られないので、配布の前（apply_template.sh）に流す。
#
# 使い方: scripts/check_skill_frontmatter.sh [スキルのディレクトリ（既定: .claude/skills）]
# 外れが1件でもあれば一覧を出して終了コード 1。0件なら 0
set -uo pipefail
# 文字数を正しく数えるため、UTF-8 のロケールで動かす
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
# このスクリプトを直したら scripts/test_check_skill_frontmatter.sh を流す

SKILLS_DIR="${1:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/.claude/skills}"
[ -d "$SKILLS_DIR" ] || { echo "ERROR: スキルのディレクトリがありません: $SKILLS_DIR" >&2; exit 2; }

fail=0
count=0

# YAML のパーサ（ruby の標準ライブラリ）が使えれば、frontmatter 全体を本物のパーサで読んで判定する（人間の決定）。
# 使えなければ、下の awk の簡易判定（必須項目の形だけ）にし、「YAML としては確かめていない」と表示する。
# CHECK_SKILL_NO_PARSER=1 で簡易判定を強制できる（テスト用）
if [ "${CHECK_SKILL_NO_PARSER:-}" != "1" ] && command -v ruby >/dev/null 2>&1 && ruby -ryaml -e 'YAML.safe_load("a: b")' >/dev/null 2>&1; then
  ruby -ryaml -e '
    dir_root = ARGV[0]
    files = Dir.glob(File.join(dir_root, "*", "SKILL.md")).sort
    if files.empty?
      puts "スキルの frontmatter: SKILL.md が1本も見つからない（#{dir_root}）"
      exit 1
    end
    fail_count = 0
    files.each do |f|
      dir = File.basename(File.dirname(f))
      problems = []
      text = File.read(f, encoding: "UTF-8")
      lines = text.lines
      if lines.first&.chomp != "---"
        problems << "frontmatter が無い"
      else
        close = lines[1..].index { |l| l.chomp == "---" }
        if close.nil?
          problems << "frontmatter が閉じていない"
        else
          begin
            fm = YAML.safe_load(lines[1, close].join)
          rescue Psych::Exception => e
            fm = nil
            problems << "YAML として読めない（#{e.message.lines.first.strip}）"
          end
          if problems.empty?
            if !fm.is_a?(Hash)
              problems << "frontmatter がキーと値の組になっていない"
            else
              n = fm["name"]
              if !n.is_a?(String) || n.empty?
                problems << "name が無いか文字列でない"
              else
                problems << "name（#{n}）がディレクトリ名と違う" if n != dir
                problems << "name（#{n}）の形が仕様に合わない" if n.length > 64 || n !~ /\A[a-z0-9]+(-[a-z0-9]+)*\z/
              end
              d = fm["description"]
              if !d.is_a?(String) || d.strip.empty?
                problems << "description が無いか、空か、文字列でない"
              elsif d.length > 1024
                problems << "description が 1024 文字を超える（#{d.length} 文字）"
              end
            end
          end
        end
      end
      unless problems.empty?
        fail_count += 1
        problems.each { |p| puts "  #{dir}: #{p}" }
      end
    end
    if fail_count > 0
      puts "スキルの frontmatter: #{files.size} 本中 #{fail_count} 本が外れ"
      exit 1
    end
    puts "スキルの frontmatter: #{files.size} 本すべて通過（YAML のパーサで確認）"
  ' "$SKILLS_DIR"
  exit $?
fi
echo "（YAML のパーサが見つからないため、必須項目の形だけを確かめます。YAML として読めるかは確かめていません）"

# YAML の1行の値として、読み込む側が確実に読める書き方かを見る（パーサを持たないので、許す形を絞る）。
#   クォートで囲むなら閉じていること・中身が空でないこと。囲まないなら「: 」「 #」を含まず、YAML の記号で始まらないこと
value_problem() {
  local v="$1"
  case "$v" in
    '"'*) [[ "$v" =~ ^\"[^\"]+\"$ ]] || { echo "クォートが閉じていないか、中身が空"; return; } ;;
    "'"*) [[ "$v" =~ ^\'[^\']+\'$ ]] || { echo "クォートが閉じていないか、中身が空"; return; } ;;
    '') echo "空"; return ;;
    [\>\|\&\*\!\%\@\`\{\[]*) echo "YAML の記号（${v:0:1}）で始まる"; return ;;
    *) case "$v" in *': '*|*' #'*) echo "クォートせずに「: 」か「 #」を含む"; return ;; esac ;;
  esac
}

for f in "$SKILLS_DIR"/*/SKILL.md; do
  [ -e "$f" ] || continue
  count=$((count + 1))
  dir="$(basename "$(dirname "$f")")"
  # 先頭の --- から次の --- までだけを読み、name と description の生の値を取り出す（本文に同じ文字列があっても拾わない）
  parsed="$(awk '
    NR == 1 { if ($0 != "---") { print "ERR\tfrontmatter が無い"; exit } ; next }
    $0 == "---" { closed = 1; exit }
    /^name:/ { names++; n = $0; sub(/^name:[ \t]*/, "", n) }
    /^description:/ { descs++; d = $0; sub(/^description:[ \t]*/, "", d) }
    END {
      if (!closed) { print "ERR\tfrontmatter が閉じていない"; exit }
      print "NAMES\t" names + 0; print "NAME\t" n
      print "DESCS\t" descs + 0; print "DESC\t" d
    }' "$f")"
  problems=""
  add() { problems="${problems}  ${dir}: $1"$'\n'; }
  if printf '%s\n' "$parsed" | grep -q '^ERR'; then
    add "$(printf '%s\n' "$parsed" | sed -n 's/^ERR\t//p')"
  else
    names="$(printf '%s\n' "$parsed" | sed -n 's/^NAMES\t//p')"
    n_raw="$(printf '%s\n' "$parsed" | sed -n 's/^NAME\t//p')"
    descs="$(printf '%s\n' "$parsed" | sed -n 's/^DESCS\t//p')"
    d_raw="$(printf '%s\n' "$parsed" | sed -n 's/^DESC\t//p')"
    if [ "$names" != "1" ]; then add "name が ${names} 個"
    else
      vp="$(value_problem "$n_raw")"; [ -n "$vp" ] && add "name の値: $vp"
      n="${n_raw#\"}"; n="${n%\"}"; n="${n#\'}"; n="${n%\'}"
      [ "$n" != "$dir" ] && add "name（${n}）がディレクトリ名と違う"
      if [ "${#n}" -gt 64 ] || ! [[ "$n" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then add "name（${n}）の形が仕様に合わない"; fi
    fi
    if [ "$descs" != "1" ]; then add "description が ${descs} 個"
    else
      vp="$(value_problem "$d_raw")"; [ -n "$vp" ] && add "description の値: $vp"
      d="${d_raw#\"}"; d="${d%\"}"; d="${d#\'}"; d="${d%\'}"
      # 文字数で数える（UTF-8 のロケールで bash の ${#} を使う。awk の length はバイト数になる環境がある）
      [ "${#d}" -gt 1024 ] && add "description が 1024 文字を超える（${#d} 文字）"
    fi
  fi
  if [ -n "$problems" ]; then
    fail=$((fail + 1))
    printf '%s' "$problems"
  fi
done

if [ "$count" -eq 0 ]; then
  echo "スキルの frontmatter: SKILL.md が1本も見つからない（${SKILLS_DIR}）"
  exit 1
fi
if [ "$fail" -gt 0 ]; then
  echo "スキルの frontmatter: ${count} 本中 ${fail} 本が外れ"
  exit 1
fi
echo "スキルの frontmatter: ${count} 本すべて通過"
