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
INCLUDES=(".mise.toml" "doc/index.md" "doc/input/" "doc/generated/")
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

  # rdd.md はプロジェクト固有。force/sync でも既存があれば守る（--overwrite-rdd で解除）
  if [ "$p" = "doc/input/" ] && [ "$OVERWRITE_RDD" != "true" ] && [ -f "$TARGET_DIR/doc/input/rdd.md" ]; then
    EXTRA_FLAGS+=("--exclude" "rdd.md")
  fi

  # 出力先ディレクトリを事前作成（dry-run時は不要）
  if [ "$DRY_RUN" = "false" ]; then
    if [[ "$p" == */ ]]; then
      mkdir -p "$TARGET_DIR/$p"
    else
      mkdir -p "$TARGET_DIR/$(dirname "$p")"
    fi
  fi

  # テンプレート側に対象が存在しない場合はスキップ
  if [ ! -e "$TEMPLATE_ROOT/$p" ]; then
    echo "SKIP: $p（テンプレートに存在しません）"
    continue
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
