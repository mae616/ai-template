#!/usr/bin/env bash
set -euo pipefail

# ai-template を任意の開発リポジトリへ反映するブートストラップ。
# - 既存ファイルを破壊しないために、上書き前にバックアップを作成する
# - まず dry-run を推奨する
#
# 使い方:
#   scripts/apply_template.sh --target /path/to/project --dry-run
#   scripts/apply_template.sh --target /path/to/project

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

TARGET_DIR=""
DRY_RUN="false"
BACKUP="true"
MODE="safe"  # safe: 既存を上書きしない / force: 上書き / sync: 上書き+削除
OVERWRITE_RDD="false"
NO_SKILLS="false"
CODEX="false"
CURSOR="false"
ANTIGRAVITY="false"

# ビルド成果物などの共通除外パターン
COMMON_EXCLUDES=(
  .git/ node_modules/ dist/ build/ .next/ out/
  coverage/ .venv/ vendor/ .cache/ target/
)

usage() {
  cat <<'USAGE'
使い方:
  scripts/apply_template.sh --target /abs/path/to/project [オプション]

オプション:
  --target <dir>   反映先（必須・絶対パス）
  --safe           既存ファイルは上書きしない（デフォルト）
  --force          テンプレ対象ファイルを上書き（バックアップ推奨）
  --sync           テンプレ対象ファイルを同期（上書き+削除）。危険
  --overwrite-rdd  doc/input/rdd.md を上書き（非推奨：通常は各プロジェクト固有）
  --no-skills      .claude/ をコピーしない（スキルはグローバルや手動管理の場合）
  --codex          Codex 向け: AGENTS.md（CLAUDE.md へのリンク）と .agents/skills（スキルごとのリンク）
  --cursor         Cursor 向け: AGENTS.md と .cursor/rules/（.claude/rules から生成。スキルは .claude/skills を直接読む）
  --antigravity    Antigravity 向け: AGENTS.md と .agents/skills と .agents/rules/（.claude/rules から生成）
                   3つは組み合わせても、1つずつ流しても同じものができる
  --dry-run        実際には書き込まず、差分だけ表示
  --no-backup      上書き前バックアップを作成しない（非推奨）
  -h, --help       ヘルプ
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)         TARGET_DIR="${2:-}"; shift 2 ;;
    --dry-run)        DRY_RUN="true"; shift ;;
    --safe)           MODE="safe"; shift ;;
    --force)          MODE="force"; shift ;;
    --sync)           MODE="sync"; shift ;;
    --overwrite-rdd)  OVERWRITE_RDD="true"; shift ;;
    --no-backup)      BACKUP="false"; shift ;;
    --no-skills)      NO_SKILLS="true"; shift ;;
    --codex)          CODEX="true"; shift ;;
    --cursor)         CURSOR="true"; shift ;;
    --antigravity)    ANTIGRAVITY="true"; shift ;;
    -h|--help)        usage; exit 0 ;;
    *)                echo "ERROR: 不明な引数: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# バリデーション
[ -z "$TARGET_DIR" ] && { echo "ERROR: --target は必須です" >&2; usage >&2; exit 2; }
[ "${TARGET_DIR:0:1}" != "/" ] && { echo "ERROR: --target は絶対パスで指定してください: $TARGET_DIR" >&2; exit 2; }
[ ! -d "$TARGET_DIR" ] && { echo "ERROR: --target が存在しません: $TARGET_DIR" >&2; exit 2; }

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' が必要です" >&2; exit 2; }; }
need rsync
need date

# 反映対象（AIテンプレとして必要最小）
INCLUDES=(".mise.toml" "doc/index.md" "doc/input/" "doc/draft/" "doc/generated/")
[ "$NO_SKILLS" = "false" ] && INCLUDES+=("CLAUDE.md" ".claude/")

# 配る前に、テンプレートのスキルの frontmatter を照合する（name・description は必須。外れがあれば配らない）
if [ "$NO_SKILLS" = "false" ]; then
  if ! bash "$TEMPLATE_ROOT/scripts/check_skill_frontmatter.sh" "$TEMPLATE_ROOT/.claude/skills"; then
    echo "ERROR: テンプレートのスキルに frontmatter の外れがあるため、配布を止めました（上の一覧を直してから再実行）" >&2
    exit 2
  fi
fi

# バックアップ
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$TARGET_DIR/.ai-template-backup/$timestamp"

if [ "$BACKUP" = "true" ] && [ "$DRY_RUN" = "false" ]; then
  mkdir -p "$backup_dir"
  for p in "${INCLUDES[@]}"; do
    [ -e "$TARGET_DIR/$p" ] || continue
    mkdir -p "$backup_dir/$(dirname "$p")"
    rsync -a -- "$TARGET_DIR/$p" "$backup_dir/$p" >/dev/null 2>&1 || true
  done
  echo "バックアップ作成: $backup_dir"
fi

# rsync フラグ構築
RSYNC_FLAGS=(-a)
[ "$DRY_RUN" = "true" ] && RSYNC_FLAGS+=("--dry-run")
case "$MODE" in
  safe)  RSYNC_FLAGS+=("--ignore-existing") ;;
  force) ;;  # 上書きのみ（削除なし）
  sync)  RSYNC_FLAGS+=("--delete") ;;
  *)     echo "ERROR: 不正なMODE: $MODE" >&2; exit 2 ;;
esac

# 共通除外を --exclude に変換
EXCLUDE_FLAGS=()
for pat in "${COMMON_EXCLUDES[@]}"; do
  EXCLUDE_FLAGS+=("--exclude" "$pat")
done

echo "テンプレート: $TEMPLATE_ROOT"
echo "反映先:       $TARGET_DIR"
echo "モード:       $MODE"
echo "overwrite-rdd: $OVERWRITE_RDD"
echo "no-skills:    $NO_SKILLS"
echo "対象:         ${INCLUDES[*]}"
echo

for p in "${INCLUDES[@]}"; do
  EXTRA_FLAGS=()

  # テンプレート側で git が無視しているファイル（ai-template 自身の引き継ぎ・ローカル設定・.DS_Store 等）は配らない。
  # ディスクから丸ごとコピーするため、無視しているものも届いてしまう。名前を列挙すると漏れるので git に聞く。
  # テンプレートが git 管理下に無い場合に備えて、最低限は固定で除外する
  EXTRA_FLAGS+=("--exclude" ".DS_Store" "--exclude" "session-context.md" "--exclude" "session-context/" "--exclude" "team-board.md")
  if [[ "$p" == */ ]] && git -C "$TEMPLATE_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    while IFS= read -r ign; do
      [ -n "$ign" ] && EXTRA_FLAGS+=("--exclude" "/${ign#"$p"}")
    done < <(git -C "$TEMPLATE_ROOT" -c core.quotePath=false ls-files --others --ignored --exclude-standard --directory -- "$p" 2>/dev/null)
  fi

  # rdd.md はプロジェクト固有。force/sync でも既存があれば守る（--overwrite-rdd で解除）
  if [ "$p" = "doc/input/" ] && [ "$OVERWRITE_RDD" != "true" ] && [ -f "$TARGET_DIR/doc/input/rdd.md" ]; then
    EXTRA_FLAGS+=("--exclude" "rdd.md")
  fi

  # 配布先のレポートはそのプロジェクトの作業記録。雛形は空の置き場だけで、force/sync でも中身を上書き・削除しない。
  # （ai-template 自身のレポートは meta/reports/ にあり、配布対象外）
  if [ "$p" = "doc/generated/" ]; then
    EXTRA_FLAGS+=("--exclude" "reports/*")
  fi

  # デザインの値・ドック・画面一覧・生成物はプロジェクト側の蓄積データ。
  # 雛形は「配布先に無いものだけ」配り、force/sync でも既存を上書き・削除しない。
  # 例外は ssot_schema.md（テンプレートが持つ契約なので更新してよい）。
  # ファイル名を列挙すると漏れるので、雛形側の実ファイルから除外リストを作る
  if [ "$p" = "doc/input/" ]; then
    EXTRA_FLAGS+=("--filter" "P /design/***")
    while IFS= read -r f; do
      rel="${f#"$TEMPLATE_ROOT/doc/input/"}"
      [ "$rel" = "design/ssot_schema.md" ] && continue
      [ -e "$TARGET_DIR/doc/input/$rel" ] && EXTRA_FLAGS+=("--exclude" "/$rel")
    done < <(find "$TEMPLATE_ROOT/doc/input/design" -type f)
  fi

  # 発酵中のドキュメントはプロジェクト固有の蓄積（未合意の検討物）。
  # 配布するのは役割を説明する README.md だけにし、中身には触らない。
  # sync の --delete で各プロジェクトの発酵物を消さないための保護でもある。
  if [ "$p" = "doc/draft/" ]; then
    EXTRA_FLAGS+=("--include" "README.md" "--exclude" "*")
  fi

  # 配布先の settings.json は各プロジェクトの設定（足した許可・外した規則）。どのモードでも上書き・削除しない。
  # 無いときだけテンプレートのものを入れる。差分は適用のあとに一覧で見せる（report_settings_diff）
  if [ "$p" = ".claude/" ] && [ -f "$TARGET_DIR/.claude/settings.json" ]; then
    EXTRA_FLAGS+=("--exclude" "/settings.json")
  fi

  # ※ プロジェクト側の蓄積ファイルを配布対象に増やす場合は、上と同様に force/sync でも守る保護を足すこと

  # 出力先ディレクトリを事前作成（dry-run時は不要）
  if [ "$DRY_RUN" = "false" ]; then
    if [[ "$p" == */ ]]; then
      mkdir -p "$TARGET_DIR/$p"
    else
      mkdir -p "$TARGET_DIR/$(dirname "$p")"
    fi
  fi

  rsync "${RSYNC_FLAGS[@]}" "${EXTRA_FLAGS[@]}" "${EXCLUDE_FLAGS[@]}" \
    -- "$TEMPLATE_ROOT/$p" "$TARGET_DIR/$p"
done

echo
if [ "$DRY_RUN" = "true" ]; then
  echo "dry-run 完了（実際の反映は行っていません）"
else
  echo "反映完了"
fi

# ---------------------------------------------------------------------------
# settings.json の差分を見せる（書き換えはしない）
# フックの実体だけ届いて登録が届かないと、フックは一度も動かないのに「守られている」と見える。
# 配布先の settings.json は各プロジェクトの設定なので、どのモードでも上書きしない（上のループで除外）。
# テンプレートにあって配布先に無いものを一覧にして、採否を人間に委ねる。
# ---------------------------------------------------------------------------

HOOK_TESTS_FAILED="false"
AGENTS_FAILED="false"

# settings.json を比較用の行に並べる。
#   hooks       → 「hooks<TAB>イベント<TAB>matcher<TAB>コマンド」
#   permissions → 「permissions.<種類><TAB>規則」
# 比べる単位は文字列の完全一致（matcher の並び順やコマンドの書き方が違うだけでも別の行になる）。
# 並べ替えと比較のロケールは C に固定する（ロケール次第で別の行がまとめられ、差が消えるのを防ぐ）
settings_lines() {
  jq -r '
    ((.hooks // {}) | to_entries[] | .key as $e | .value[] | (.matcher // "") as $m
      | (.hooks // [])[] | "hooks\t\($e)\t\($m)\t\(.command)"),
    ((.permissions // {}) | to_entries[] | select(.value | type == "array") | .key as $k
      | .value[] | "permissions.\($k)\t\(.)")
  ' "$1" | LC_ALL=C sort -u
}

# 登録されているフックのコマンドだけを並べる（settings.json と、あれば settings.local.json）。
# JSON として読めないファイルは、そう表示して対象から外す（set -e で黙って止まらないよう、戻り値は常に0）
registered_hook_commands() {
  local f
  for f in "$TARGET_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.local.json"; do
    [ -f "$f" ] || continue
    if ! jq -e 'type == "object"' "$f" >/dev/null 2>&1; then
      echo "  ${f#"$TARGET_DIR/"} が JSON のオブジェクトとして読めないため、登録の確認から外しました" >&2
      continue
    fi
    jq -r '(.hooks // {}) | to_entries[] | .value[] | (.hooks // [])[] | .command // empty' "$f" 2>/dev/null || true
  done
  return 0
}

# テンプレートにあって配布先に無い hooks / permissions と、置かれているのに登録されていないフックを表示する。
# JSON として読めないファイルは比較しない（読めないまま比べると、全項目が「無い」と誤って出るため）
report_settings_diff() {
  local tpl="$TEMPLATE_ROOT/.claude/settings.json"
  local dst="$TARGET_DIR/.claude/settings.json"
  [ -f "$tpl" ] || return 0
  echo
  echo "== settings.json の確認（どのモードでも書き換えません）=="
  if ! command -v jq >/dev/null 2>&1; then
    echo "  jq が無いため比較できません。テンプレートの .claude/settings.json と手で見比べてください"
    return 0
  fi
  if [ ! -f "$dst" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "  配布先に settings.json がありません。反映するとテンプレートのものがそのまま入ります"
    else
      echo "  配布先に settings.json がありません（コピーに失敗した可能性があります）"
    fi
    return 0
  fi
  if ! jq -e 'type == "object"' "$dst" >/dev/null 2>&1; then
    echo "  配布先の .claude/settings.json が JSON のオブジェクトとして読めません（空のファイルを含む）。Claude Code もこの設定を読めていない可能性があります。直してから再実行してください"
    return 0
  fi
  if ! jq -e 'type == "object"' "$tpl" >/dev/null 2>&1; then
    echo "  テンプレートの .claude/settings.json が JSON として読めません"
    return 0
  fi
  local missing
  missing="$(LC_ALL=C comm -23 <(settings_lines "$tpl") <(settings_lines "$dst"))"
  if [ -z "$missing" ]; then
    echo "  テンプレートにあって配布先に無い hooks / permissions: 0件"
  else
    echo "  テンプレートにあって配布先に無い hooks / permissions: $(printf '%s\n' "$missing" | wc -l | tr -d ' ')件"
    printf '%s\n' "$missing" | sed 's/^/    /'
    echo "  → 採否を決めて、配布先の .claude/settings.json に手で足してください（足さないと、そのフック・規則は効きません）"
  fi

  # 置かれているのに登録されていないフック（実体だけ届いた状態）。コマンドの末尾が「/<名前>」のものだけを登録とみなす
  local unregistered="" cmds f name
  cmds="$(registered_hook_commands)"
  if [ -d "$TARGET_DIR/.claude/hooks" ]; then
    for f in "$TARGET_DIR"/.claude/hooks/*.sh; do
      [ -e "$f" ] || continue
      name="$(basename "$f")"
      case "$name" in test-*) continue ;; esac
      # 「/名前」の直後が終わり・空白・引用符なら登録とみなす（名前は正規表現ではなく文字列として探す）
      printf '%s\n' "$cmds" | awk -v n="$name" '{ i = index($0, n); while (i > 0) { pre = (i == 1) ? "" : substr($0, i - 1, 1); post = substr($0, i + length(n), 1); if ((pre == "" || pre == "/") && (post == "" || post ~ /[[:space:]"\047]/)) { found = 1 } j = index(substr($0, i + 1), n); i = (j > 0) ? i + j : 0 } } END { exit(found ? 0 : 1) }' || unregistered="${unregistered}    .claude/hooks/$name"$'\n'
    done
  fi
  if [ -n "$unregistered" ]; then
    echo "  置かれているのに settings.json / settings.local.json に登録されていないフック:"
    printf '%s' "$unregistered"
  fi
}

# 配布先の .claude/hooks/test-*.sh を流して結果を見せる（実体・登録・テストの3つで接続済み）。
# 流す検証スクリプトはテンプレートと中身が同じものだけ（検証スクリプトが叩くのは配布先のフック本体）。
# 入力は閉じ、timeout があれば1本120秒で止める。1本でも FAIL なら HOOK_TESTS_FAILED を立てる（終了コードに反映）
run_hook_tests() {
  [ "$DRY_RUN" = "true" ] && return 0
  local f out rc base tpl_f
  local found="false" tmo="" skipped=0
  command -v timeout >/dev/null 2>&1 && tmo="timeout 120"
  command -v gtimeout >/dev/null 2>&1 && [ -z "$tmo" ] && tmo="gtimeout 120"
  echo
  echo "== フックの検証スクリプト =="
  for f in "$TARGET_DIR"/.claude/hooks/test-*.sh; do
    [ -e "$f" ] || continue
    found="true"
    base="$(basename "$f")"
    tpl_f="$TEMPLATE_ROOT/.claude/hooks/$base"
    if [ ! -f "$tpl_f" ] || ! cmp -s "$f" "$tpl_f"; then
      echo "  SKIP ${base}（中身がテンプレートと異なるので実行しません。必要なら手で流してください）"
      skipped=$((skipped + 1))
      continue
    fi
    # set -e の下でも失敗を拾えるように、終了コードを分けて受ける
    if out="$($tmo bash "$f" </dev/null 2>&1)"; then rc=0; else rc=$?; fi
    if [ "$rc" -eq 0 ]; then
      echo "  OK   $base"
    else
      HOOK_TESTS_FAILED="true"
      echo "  FAIL ${base}（終了コード ${rc}）"
      printf '%s\n' "$out" | tail -n 5 | sed 's/^/       /'
    fi
  done
  [ "$found" = "false" ] && echo "  検証スクリプトがありません"
  [ "$skipped" -gt 0 ] && echo "  ${skipped} 本は検証していません（SKIP）"
  return 0
}

if [ "$NO_SKILLS" = "false" ]; then
  report_settings_diff
  run_hook_tests
fi

# ---------------------------------------------------------------------------
# ほかのエージェント向け（--codex / --cursor / --antigravity を付けたときだけ作る。人間の決定）
# 写しはずれるので、リンクで済むものはリンクにし、形を変えないと読まれないもの（rules）だけ生成する。
#   - AGENTS.md → CLAUDE.md へのリンク（Codex・Cursor・Antigravity の3つとも、リンクを辿って読む。2026-10-04 実機で確認）
#   - .agents/skills/<名前> → ../../.claude/skills/<名前>（Codex・Antigravity。Cursor も読む）
#     .agents/skills そのものをリンクにすると Codex に読まれない（openai/codex#11314）。スキルごとのリンクは辿る（実機で確認）
#   - rules: Claude Code 以外は .claude/rules/ を自動では読まない
#       Cursor      → .cursor/rules/ai-template-<名前>.mdc（alwaysApply: true。Claude Code と同じく常に効かせる）
#       Antigravity → .agents/rules/ai-template-<名前>.md（trigger: model_decision。常に効く決まりの合計 20,000 トークンの上限に、
#                     CLAUDE.md と rules を合わせるとぎりぎりのため。trigger を必ず付けるのは、無いファイルは黙って捨てられるため）
#       Codex       → 生成しない。CLAUDE.md に「自動で読み込まれない環境では作業の前に読む」と書いてある（読むかは AI 次第）
# 写しを照合する時点は「このスクリプトを流すたび」。選んでいない道具の生成物も見比べ、ずれていれば知らせる（書き換えない）
# 出典: Codex「Build skills」「AGENTS.md」、Cursor「Agent Skills」「Rules」、Antigravity「Agent skills」「Rules」（2026-10-03 確認）
# ---------------------------------------------------------------------------
# 生成物の印。frontmatter（4行）の直後の5行目に置き、見分けるときもこの位置だけを見る
GENERATED_MARK="<!-- 生成物: scripts/apply_template.sh が .claude/rules/ から作る。手で直さない（元を直して流し直す） -->"
GENERATED_PREFIX="<!-- 生成物: scripts/apply_template.sh"
ANTIGRAVITY_MAX_BYTES=24000
CODEX_MAX_BYTES=32768
NOTE_DRY=""
[ "$DRY_RUN" = "true" ] && NOTE_DRY="。dry-run のため書いていません"

# 生成物かどうか（5行目が印で始まるか）
is_generated() {
  [ -f "$1" ] || return 1
  case "$(sed -n '5p' "$1")" in "$GENERATED_PREFIX"*) return 0 ;; esac
  return 1
}

# ディレクトリ $1 に、名前 $2 の項目が大文字・小文字まで同じ綴りであるか。
# 大文字・小文字を区別しないファイルシステム（macOS の標準）では、-e は綴りの違う古い名前でも真になるため、一覧で確かめる
exact_name_exists() {
  ls -A "$1" 2>/dev/null | grep -qxF -- "$2"
}

# 大文字・小文字を区別せずに同じ文字列か
same_ignoring_case() {
  [ "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')" ]
}

# 1行目が --- で、閉じの --- があるときだけ frontmatter とみなす（区切り線で始まるだけの rule を取り違えない）。CRLF と BOM は除いて見る
has_frontmatter() {
  tr -d '\r' < "$1" | LC_ALL=C sed $'1s/^\xef\xbb\xbf//' | awk 'NR == 1 { if ($0 != "---") exit 1; next } $0 == "---" { found = 1; exit } END { exit(found ? 0 : 1) }'
}

# 印つきの写しを上書き・削除する前に退避する（手で直していた場合に備えて）。--no-backup と dry-run では何もしない
#   $1: 写しのパス、$2: 配布先からの置き場（.cursor/rules など）
backup_copy() {
  [ "$BACKUP" = "true" ] && [ "$DRY_RUN" = "false" ] || return 0
  # 退避先の途中がリンクなら、辿ると配布先の外へ書くので退避しない（呼び出し側は上書き・削除もしない）
  if path_has_link "${backup_dir#"$TARGET_DIR/"}/$2"; then
    echo "  失敗: 退避先（.ai-template-backup）の途中がリンクのため、$2/$(basename "$1") を上書き・削除しません"
    return 1
  fi
  if mkdir -p "$backup_dir/$2" && cp -p "$1" "$backup_dir/$2/"; then return 0; fi
  echo "  失敗: $2/$(basename "$1") を退避できなかったため、上書き・削除しません"
  return 1
}

# 置き場（$1。配布先からの相対パス）の途中に、ディレクトリではないものがあれば真（作れないので「失敗:」で1行だけ知らせる）
path_has_nondir() {
  local rel="$1" acc="$TARGET_DIR" part
  local IFS=/
  for part in $rel; do
    acc="$acc/$part"
    [ -e "$acc" ] && [ ! -d "$acc" ] && return 0
  done
  return 1
}

# 反映後の配布先で、相対パス $1 の中身を読むべき実ファイルを出力する（無ければ何も出さない）。
# dry-run ではまだコピーしていないので、モードから求める（safe: 配布先にあれば配布先 / force: テンプレート優先 / sync: テンプレートだけ）
after_apply_path() {
  local rel="$1"
  if [ "$DRY_RUN" = "false" ]; then
    if [ -e "$TARGET_DIR/$rel" ] || [ -L "$TARGET_DIR/$rel" ]; then echo "$TARGET_DIR/$rel"; fi
    return 0
  fi
  # 配布先のリンク切れも「ある」とみなす（rsync の safe はそれを上書きしない。読めるかは呼び出し側が -r で見る）
  case "$MODE" in
    safe)  if [ -e "$TARGET_DIR/$rel" ] || [ -L "$TARGET_DIR/$rel" ]; then echo "$TARGET_DIR/$rel"; elif [ -e "$TEMPLATE_ROOT/$rel" ]; then echo "$TEMPLATE_ROOT/$rel"; fi ;;
    force) if [ -e "$TEMPLATE_ROOT/$rel" ]; then echo "$TEMPLATE_ROOT/$rel"; elif [ -e "$TARGET_DIR/$rel" ] || [ -L "$TARGET_DIR/$rel" ]; then echo "$TARGET_DIR/$rel"; fi ;;
    sync)  if [ -e "$TEMPLATE_ROOT/$rel" ]; then echo "$TEMPLATE_ROOT/$rel"; fi ;;
  esac
  return 0
}

# 反映後の配布先にあるスキル名（$1=skills）または rule 名（$1=rules）を並べる。
# rule 名は .claude/rules/ からの相対パス（.md を除く）。Claude Code はサブディレクトリの rule も読むので、同じく拾う
after_apply_names() {
  local kind="$1" root p
  local roots=("$TARGET_DIR")
  if [ "$DRY_RUN" = "true" ]; then
    roots=("$TEMPLATE_ROOT")
    [ "$MODE" != "sync" ] && roots+=("$TARGET_DIR")
  fi
  for root in "${roots[@]}"; do
    if [ "$kind" = "skills" ]; then
      for p in "$root"/.claude/skills/*/SKILL.md; do [ -e "$p" ] && basename "$(dirname "$p")"; done
    else
      [ -d "$root/.claude/rules" ] || continue
      # リンクのディレクトリの中も辿る（Claude Code はリンクで共有した rules も読む）。-L の下でリンク切れは -type l に当たる
      find -L "$root/.claude/rules" \( -type f -o -type l \) -name '*.md' | while IFS= read -r p; do
        p="${p#"$root/.claude/rules/"}"; echo "${p%.md}"
      done
    fi
  done | LC_ALL=C sort -u
  return 0
}

# 反映後の rules を、エラーなく列挙できるか（find は読めないディレクトリがあると 0 以外を返す）
rules_listable() {
  local root
  local roots=("$TARGET_DIR")
  if [ "$DRY_RUN" = "true" ]; then
    roots=("$TEMPLATE_ROOT")
    [ "$MODE" != "sync" ] && roots+=("$TARGET_DIR")
  fi
  for root in "${roots[@]}"; do
    [ -d "$root/.claude/rules" ] || continue
    find -L "$root/.claude/rules" >/dev/null || return 1
  done
  return 0
}

# 配布先の中で、$1（相対パス）に至るどこかがリンクなら真。リンク越しに書くと配布先の外へ書き込むため
path_has_link() {
  local rel="$1" acc="$TARGET_DIR" part
  local IFS=/
  for part in $rel; do
    acc="$acc/$part"
    [ -L "$acc" ] && return 0
  done
  return 1
}

# AGENTS.md を CLAUDE.md へのリンクにする。手で書いたファイルや、別の場所を指すリンクには触らない
#   $1: 3つのどれかを選んだら "true"
ensure_agents_link() {
  local selected="$1" dst="$TARGET_DIR/AGENTS.md" claude size
  # Codex は AGENTS.md を既定で 32 KiB までしか読まない（超えた分は読まれない）。リンクがあれば、選んでいなくても毎回照合する
  claude="$(after_apply_path CLAUDE.md)"
  if { [ "$selected" = "true" ] || [ "$(readlink "$dst" 2>/dev/null)" = "CLAUDE.md" ]; } && [ -n "$claude" ] && [ -r "$claude" ]; then
    size="$(wc -c < "$claude" | tr -d ' ')"
    if [ "$size" -gt "$CODEX_MAX_BYTES" ]; then
      echo "  ⚠️ CLAUDE.md（AGENTS.md）が ${size} バイトで、Codex の既定の読み込み上限（${CODEX_MAX_BYTES} バイト）を超えます。超えた分は Codex に読まれません"
    fi
  fi
  [ "$selected" = "true" ] || return 0
  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "CLAUDE.md" ] && [ -z "$(after_apply_path CLAUDE.md)" ]; then
      echo "  AGENTS.md: CLAUDE.md へのリンクがありますが、CLAUDE.md が無いためリンク切れです"
    elif [ "$(readlink "$dst")" = "CLAUDE.md" ]; then
      echo "  AGENTS.md: CLAUDE.md へのリンクがあります（そのまま）"
    else
      echo "  SKIP AGENTS.md（別の場所を指すリンクがあるため触りません）"
    fi
  elif [ -e "$dst" ]; then
    echo "  SKIP AGENTS.md（手で書かれたファイルがあるため触りません。CLAUDE.md を読ませるなら、中身を移してからリンクにしてください）"
  elif [ -z "$(after_apply_path CLAUDE.md)" ]; then
    echo "  AGENTS.md: CLAUDE.md が無いため作りません"
  elif [ "$DRY_RUN" = "true" ]; then
    echo "  AGENTS.md: CLAUDE.md へのリンクを作ります${NOTE_DRY}"
  elif ln -s CLAUDE.md "$dst"; then
    echo "  AGENTS.md: CLAUDE.md へのリンクを作りました"
  else
    echo "  失敗: AGENTS.md のリンクを作れませんでした（上のエラーを見てください）"
  fi
  return 0
}

# .agents/skills にスキルごとのリンクを置く。自分が置いた形のリンク（../../.claude/skills/<名前>）だけを扱い、ほかには触らない
#   $1: 作るなら "true"。"false" なら、前に作ったリンクが今のスキルとずれていないかだけを見る
sync_skill_links() {
  local selected="$1" base="$TARGET_DIR/.agents/skills" name link want cur made=0 kept=0 skipped=0 failed=0 missing=0 removed=0 ours=0
  if [ "$selected" = "true" ] && path_has_link ".agents/skills"; then
    echo "  .agents/skills: .agents か .agents/skills がリンクになっているため作りません（配布先の外へ書き込むのを避けるため。Codex もリンクのディレクトリは読みません）"
    return 0
  fi
  if [ "$selected" = "true" ] && path_has_nondir ".agents/skills"; then
    echo "  失敗: .agents/skills の途中にディレクトリではないものがあるため作れません"
    return 0
  fi
  if [ "$selected" = "false" ]; then
    [ -d "$base" ] && ! path_has_link ".agents/skills" || return 0
  fi
  local names
  names="$(after_apply_names skills)"
  if [ "$selected" = "true" ] && [ -z "$names" ]; then
    echo "  .agents/skills: 配布先に .claude/skills のスキルが無いため作りません"
    return 0
  fi
  [ "$selected" = "true" ] && [ "$DRY_RUN" = "false" ] && mkdir -p "$base"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    link="$base/$name"
    want="../../.claude/skills/$name"
    if [ -L "$link" ]; then
      cur="$(readlink "$link")"
      if [ "$cur" = "$want" ]; then
        kept=$((kept + 1))
      elif same_ignoring_case "$cur" "$want"; then
        # スキルの名前を大文字・小文字だけ変えた（macOS では古い名前のリンクが同じ場所に見える）。古いリンクを外して作り直す
        if [ "$selected" = "false" ]; then
          missing=$((missing + 1))
        elif [ "$DRY_RUN" = "true" ]; then
          made=$((made + 1))
        elif rm -- "$link" && ln -s "$want" "$link"; then
          made=$((made + 1)); echo "  名前の大文字・小文字が変わったスキルのリンクを作り直しました: .agents/skills/${name}"
        else
          failed=$((failed + 1)); echo "  失敗: .agents/skills/${name} のリンクを作り直せませんでした（上のエラーを見てください）"
        fi
      else
        skipped=$((skipped + 1)); [ "$selected" = "true" ] && echo "  SKIP .agents/skills/${name}（別の場所を指すリンクがあるため触りません）"
      fi
    elif [ -e "$link" ]; then
      skipped=$((skipped + 1)); [ "$selected" = "true" ] && echo "  SKIP .agents/skills/${name}（リンクではないものがあるため触りません）"
    elif [ "$selected" = "false" ]; then
      missing=$((missing + 1))
    elif [ "$DRY_RUN" = "true" ]; then
      made=$((made + 1))
    elif ln -s "$want" "$link"; then
      made=$((made + 1))
    else
      failed=$((failed + 1)); echo "  失敗: .agents/skills/${name} のリンクを作れませんでした（上のエラーを見てください）"
    fi
  done <<< "$names"
  # 自分が置いた形のリンクのうち、元のスキルが反映後に無くなるもの
  for link in "$base"/*; do
    [ -L "$link" ] || continue
    name="$(basename "$link")"
    [ "$(readlink "$link")" = "../../.claude/skills/$name" ] || continue
    ours=$((ours + 1))
    printf '%s\n' "$names" | grep -qxF -- "$name" && continue
    if [ "$selected" = "true" ]; then
      if [ "$DRY_RUN" = "false" ] && ! rm -- "$link"; then
        echo "  失敗: .agents/skills/${name} を外せませんでした（上のエラーを見てください）"; continue
      fi
      removed=$((removed + 1)); echo "  元のスキルが無いリンクを外します: .agents/skills/${name}${NOTE_DRY}"
    else
      missing=$((missing + 1))
    fi
  done
  if [ "$selected" = "true" ]; then
    echo "  .agents/skills: 作る ${made} 本・そのまま ${kept} 本・SKIP ${skipped} 本・外す ${removed} 本・失敗 ${failed} 本${NOTE_DRY}"
  elif [ "$ours" -gt 0 ] || [ "$kept" -gt 0 ]; then
    if [ "$missing" -gt 0 ]; then
      echo "  ⚠️ .agents/skills: 今のスキルとずれています（リンクの足りない・リンク切れ ${missing} 本）。--codex か --antigravity で流し直してください"
    else
      echo "  .agents/skills: 今回は選んでいません（前に作ったリンクは今のスキルと合っています）"
    fi
  fi
  return 0
}

# rules の写し1件分を標準出力に書く
#   $1: cursor | antigravity、$2: rule 名（.claude/rules/ からの相対パス）、$3: 元のファイル
render_rule() {
  local tool="$1" name="$2" src="$3" title desc
  # 見出しは最初の「# 」行。コードブロックの中の行は拾わない
  title="$(tr -d '\r' < "$src" | awk '/^(```|~~~)/ { fence = !fence; next } !fence && /^# / { sub(/^# /, ""); print; exit }')"
  desc="${title:-$name}（.claude/rules/${name}.md）"
  [ "$tool" = "antigravity" ] && desc="${desc}。この作業に関係するなら読む"
  # YAML の単引用符で囲む（中の ' は '' にする。\ や " はそのまま通る）
  # bash 3.2 と 5 で ${var//\'/...} の結果が違うので、sed で置き換える
  desc="'$(printf '%s' "$desc" | sed "s/'/''/g")'"
  echo "---"
  if [ "$tool" = "cursor" ]; then
    echo "description: $desc"
    echo "alwaysApply: true"
  else
    echo "trigger: model_decision"
    echo "description: $desc"
  fi
  echo "---"
  echo "$GENERATED_MARK"
  echo
  cat "$src"
}

# rules の写しを、道具ごとの置き場に生成する。生成物の印が5行目にあるファイルだけを作り直し・外し、ほかには触らない
#   $1: cursor | antigravity、$2: 作るなら "true"。"false" なら、前の生成物が今の rules とずれていないかだけを見る
# 失敗した書き込みは「失敗:」で始まる行で知らせる（呼び出し側が終了コードに反映する）
sync_rule_copies() {
  local tool="$1" selected="$2" rel ext flag
  if [ "$tool" = "cursor" ]; then rel=".cursor/rules"; ext="mdc"; flag="--cursor"; else rel=".agents/rules"; ext="md"; flag="--antigravity"; fi
  local dir="$TARGET_DIR/$rel" name src out base tmp next_tmp="" existed reason made=0 updated=0 kept=0 skipped=0 removed=0 stale=0 missing=0 generated=0
  if path_has_link "$rel"; then
    [ "$selected" = "true" ] && echo "  ${rel}: 途中のディレクトリがリンクになっているため作りません（配布先の外へ書き込むのを避けるため）"
    return 0
  fi
  if [ "$selected" = "true" ] && path_has_nondir "$rel"; then
    echo "  失敗: ${rel} の途中にディレクトリではないものがあるため作れません"
    return 0
  fi
  if [ "$selected" = "false" ] && [ ! -d "$dir" ]; then return 0; fi
  # rules を読み切れない（権限が無い等）と、写しを「元が無い」と取り違えて外してしまうので、何も触らずに止める
  if ! rules_listable; then
    echo "  失敗: .claude/rules/ を読み切れないため、${rel} には触りません（上のエラーを見てください）"
    return 0
  fi
  local names expected=""
  names="$(after_apply_names rules)"
  [ "$selected" = "true" ] && [ "$DRY_RUN" = "false" ] && mkdir -p "$dir"
  tmp="$(mktemp)"
  # 写し先の名前がぶつかるもの（front/ui.md と front--ui.md など）。どちらも作らない
  local dups
  # 大文字・小文字を区別しないファイルシステム（macOS の標準）でも同じ場所になるので、区別せずに比べる
  dups="$(printf '%s\n' "$names" | while IFS= read -r name; do [ -n "$name" ] && echo "ai-template-${name//\//--}.$ext"; done | LC_ALL=C sort -f | LC_ALL=C uniq -di)"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    src="$(after_apply_path ".claude/rules/$name.md")"
    # サブディレクトリの rule は、区切りの / を -- にして平たく置く
    base="ai-template-${name//\//--}.$ext"
    out="$dir/$base"
    expected="${expected}${base}"$'\n'
    # 写し先そのものがリンクなら、辿ると配布先の外へ書き込むことがあるので触らない
    if [ -L "$out" ]; then
      skipped=$((skipped + 1)); [ "$selected" = "true" ] && echo "  SKIP ${rel}/${base}（リンクがあるため触りません）"
      continue
    fi
    if [ -e "$out" ] && ! is_generated "$out"; then
      skipped=$((skipped + 1)); [ "$selected" = "true" ] && echo "  SKIP ${rel}/${base}（生成物の印が無い。手で書かれたものなので触りません）"
      continue
    fi
    existed="false"
    if [ -e "$out" ]; then existed="true"; generated=$((generated + 1)); fi
    # 写せない rule。既にある写しは、選んでいれば外し（古い中身が別の効き方で残るのを防ぐ）、選んでいなければずれとして数える
    reason=""
    if printf '%s\n' "$dups" | LC_ALL=C grep -qixF -- "$base"; then
      reason="dup"
    elif [ -z "$src" ] || [ ! -r "$src" ]; then
      reason="unreadable"
    elif has_frontmatter "$src"; then
      reason="frontmatter"
    fi
    if [ -n "$reason" ]; then
      if [ "$selected" = "false" ]; then
        if [ "$existed" = "true" ]; then stale=$((stale + 1)); elif [ "$reason" != "frontmatter" ]; then missing=$((missing + 1)); fi
        continue
      fi
      case "$reason" in
        dup)         echo "  失敗: ${rel}/${base} は、別の rule と写し先の名前がぶつかるため作れません（どちらかの名前を変えてください）" ;;
        unreadable)  echo "  失敗: .claude/rules/${name}.md を読めないため ${rel}/${base} を作れません（リンク切れなど）" ;;
        frontmatter) skipped=$((skipped + 1)); echo "  SKIP ${rel}/${base}（元の .claude/rules/${name}.md に frontmatter があり、効く範囲を写せないため作りません。必要なら手で置いてください）" ;;
      esac
      # 退避できなければ外さない（backup_copy が「失敗:」を出す）
      if [ "$existed" = "true" ] && [ "$reason" != "dup" ] && backup_copy "$out" "$rel"; then
        if [ "$DRY_RUN" = "false" ] && ! rm -- "$out"; then
          echo "  失敗: ${rel}/${base} を外せませんでした（上のエラーを見てください）"
        else
          removed=$((removed + 1)); echo "  写せなくなった rule の古い生成物を外します: ${rel}/${base}${NOTE_DRY}"
        fi
      fi
      continue
    fi
    render_rule "$tool" "$name" "$src" > "$tmp"
    # 上限は、作るとき・そのままのとき・選んでいないときのどれでも知らせる（中身が同じだと黙る形にしない）
    if [ "$tool" = "antigravity" ] && { [ "$selected" = "true" ] || [ "$existed" = "true" ]; } \
      && [ "$(wc -c < "$tmp" | tr -d ' ')" -gt "$ANTIGRAVITY_MAX_BYTES" ]; then
      echo "  ⚠️ ${rel}/${base} が Antigravity の1ファイルの上限（${ANTIGRAVITY_MAX_BYTES} バイト。超えた分は切り捨てられる）を超えます。元の .claude/rules/${name}.md を分けてください"
    fi
    if [ "$existed" = "true" ]; then
      if cmp -s "$tmp" "$out"; then kept=$((kept + 1)); continue; fi
      if [ "$selected" = "false" ]; then stale=$((stale + 1)); continue; fi
    elif [ "$selected" = "false" ]; then
      missing=$((missing + 1)); continue
    fi
    if [ "$DRY_RUN" = "false" ]; then
      # 印つきの写しを手で直していた場合に備えて、上書きする前に退避する
      if [ "$existed" = "true" ] && ! backup_copy "$out" "$rel"; then continue; fi
      # rule の名前を大文字・小文字だけ変えた（macOS では古い名前の写しが同じ場所に見える）。古い名前を外してから正しい名前で置く
      if [ "$existed" = "true" ] && ! exact_name_exists "$dir" "$base" && ! rm -- "$out"; then
        echo "  失敗: ${rel} の古い名前の写しを外せませんでした（上のエラーを見てください）"
        continue
      fi
      # 同じ置き場に一時ファイルを作って置き換える（その場で書き換えると、ハードリンク先の外のファイルまで変わるため）
      if ! { next_tmp="$(mktemp "$dir/.ai-template.XXXXXX")" && cp "$tmp" "$next_tmp" && chmod 644 "$next_tmp" && mv -f "$next_tmp" "$out"; }; then
        [ -n "${next_tmp:-}" ] && rm -f "$next_tmp"
        echo "  失敗: ${rel}/${base} を書けませんでした（上のエラーを見てください）"
        continue
      fi
    fi
    if [ "$existed" = "true" ]; then updated=$((updated + 1)); else made=$((made + 1)); fi
  done <<< "$names"
  rm -f "$tmp"
  # 元の rule が反映後に無くなる生成物（リンクには触らない）
  for out in "$dir"/ai-template-*."$ext"; do
    [ -e "$out" ] && [ ! -L "$out" ] || continue
    is_generated "$out" || continue
    base="$(basename "$out")"
    printf '%s' "$expected" | grep -qxF -- "$base" && continue
    generated=$((generated + 1))
    if [ "$selected" = "false" ]; then stale=$((stale + 1)); continue; fi
    backup_copy "$out" "$rel" || continue
    if [ "$DRY_RUN" = "false" ] && ! rm -- "$out"; then
      echo "  失敗: ${rel}/${base} を外せませんでした（上のエラーを見てください）"
      continue
    fi
    removed=$((removed + 1)); echo "  元の rule が無い生成物を外します: ${rel}/${base}${NOTE_DRY}"
  done
  if [ "$selected" = "true" ]; then
    echo "  ${rel}: 作る ${made} 件・作り直す ${updated} 件・そのまま ${kept} 件・SKIP ${skipped} 件・外す ${removed} 件${NOTE_DRY}"
  elif [ "$generated" -gt 0 ] && [ $((stale + missing)) -gt 0 ]; then
    echo "  ⚠️ ${rel}: 今の .claude/rules/ とずれています（中身が違う・元が無い ${stale} 件、写しの無い rule ${missing} 件）。${flag} で流し直してください"
  elif [ "$generated" -gt 0 ]; then
    echo "  ${rel}: 今回は選んでいません（前の生成物は今の rules と合っています）"
  fi
  return 0
}

if [ "$NO_SKILLS" = "true" ]; then
  if [ "$CODEX" = "true" ] || [ "$CURSOR" = "true" ] || [ "$ANTIGRAVITY" = "true" ]; then
    echo
    echo "== ほかのエージェント向け =="
    echo "  --no-skills のため作りません（.claude/ と CLAUDE.md を配らないので、リンクと写しの元がありません）"
  fi
else
  any_agent="false"
  { [ "$CODEX" = "true" ] || [ "$CURSOR" = "true" ] || [ "$ANTIGRAVITY" = "true" ]; } && any_agent="true"
  skills_selected="false"
  { [ "$CODEX" = "true" ] || [ "$ANTIGRAVITY" = "true" ]; } && skills_selected="true"
  # 何も言うことが無ければ見出しも出さないために、出力をまとめて受ける（エラーの表示も同じ順に並べる）
  # 途中で落ちても（変数の書き間違い・シグナル等）、受けた出力を捨てずに見せてから失敗にする
  if agents_out="$({
    ensure_agents_link "$any_agent"
    sync_skill_links "$skills_selected"
    sync_rule_copies cursor "$CURSOR"
    sync_rule_copies antigravity "$ANTIGRAVITY"
  } 2>&1)"; then agents_rc=0; else agents_rc=$?; fi
  if [ "$agents_rc" -ne 0 ]; then
    agents_out="${agents_out}"$'\n'"  失敗: ほかのエージェント向けの処理が途中で止まりました（終了コード ${agents_rc}）。上の出力までは反映されています"
  fi
  if [ -n "$agents_out" ]; then
    echo
    echo "== ほかのエージェント向け（codex=${CODEX} cursor=${CURSOR} antigravity=${ANTIGRAVITY}）=="
    printf '%s\n' "$agents_out"
    if [ "$CURSOR" = "true" ] && { [ "$skills_selected" = "true" ] || [ -d "$TARGET_DIR/.agents/skills" ]; }; then
      echo "  ※ Cursor は .claude/skills と .agents/skills の両方を読みます。cursor-agent では同じ名前を1件にまとめて表示しました（2026-10-04 実測）。エディタで2つ見えたら、どちらも同じスキルです"
    fi
    if printf '%s\n' "$agents_out" | grep -q '^  失敗: '; then
      AGENTS_FAILED="true"
    fi
  fi
fi

# 失敗は両方とも見せてから終える（終了コードはフックの検証を優先: 3、ほかのエージェント向けだけなら 4）
if [ "$AGENTS_FAILED" = "true" ]; then
  echo
  echo "ほかのエージェント向けのファイルで、書けなかったものがあります。「失敗:」の行を見て直してください"
fi
if [ "$HOOK_TESTS_FAILED" = "true" ]; then
  echo
  echo "反映は済みましたが、フックの検証が失敗しました。FAIL の行を見て直してください"
  exit 3
fi
[ "$AGENTS_FAILED" = "true" ] && exit 4
exit 0
