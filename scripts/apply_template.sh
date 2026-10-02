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
# doc/output/ は送り状（to-template.md）の雛形を新規プロジェクトへ配布するために含める
INCLUDES=(".mise.toml" "doc/index.md" "doc/input/" "doc/draft/" "doc/generated/" "doc/output/")
[ "$NO_SKILLS" = "false" ] && INCLUDES+=("CLAUDE.md" ".claude/")

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

  # 送り状はプロジェクト側の蓄積データ（未取込の学び）。force/sync でも既存があれば守る
  # ※ プロジェクト側の蓄積ファイルを配布対象に増やす場合は、ここに同様の保護を足すこと
  if [ "$p" = "doc/output/" ] && [ -f "$TARGET_DIR/doc/output/to-template.md" ]; then
    EXTRA_FLAGS+=("--exclude" "to-template.md")
  fi

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

if [ "$HOOK_TESTS_FAILED" = "true" ]; then
  echo
  echo "反映は済みましたが、フックの検証が失敗しました。FAIL の行を見て直してください"
  exit 3
fi
