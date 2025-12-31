#!/usr/bin/env bash
set -euo pipefail

# ai-template を任意の開発リポジトリへ反映するブートストラップ。
# - 既存ファイルを破壊しないために、上書き前にバックアップを作成する
# - まず dry-run を推奨する
#
# 使い方:
#   scripts/apply_template.sh --target /path/to/project --dry-run
#   scripts/apply_template.sh --target /path/to/project
#
# 想定:
# - このスクリプトは ai-template リポジトリ内から実行する
# - 反映対象は「AI開発支援用のファイル群」に限定する

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

TARGET_DIR=""
DRY_RUN="false"
BACKUP="true"
MODE="safe" # safe(default): 既存を上書きしない / force: 上書きする / sync: 上書き＋削除で同期（危険）
OVERWRITE_RDD="false"
OVERWRITE_AI_TASK="false"

usage() {
  cat <<'USAGE'
使い方:
  scripts/apply_template.sh --target /abs/path/to/project [--safe|--force|--sync] [--dry-run] [--no-backup]

オプション:
  --target <dir>   反映先（必須）
  --safe           既存ファイルは上書きしない（デフォルト）
  --force          テンプレ対象ファイルを上書きする（バックアップ推奨）
  --sync           テンプレ対象ファイルを同期（上書き＋削除）。危険：テンプレ配下で削除が発生しうる
  --overwrite-rdd  `doc/rdd.md` を上書きする（非推奨：通常は各プロジェクト固有）
  --overwrite-ai-task  `ai-task/`（テンプレ）を上書きする（注意：既存タスクを壊す可能性）
  --dry-run        実際には書き込まず、差分だけ表示
  --no-backup      上書き前バックアップを作成しない（非推奨）
  -h, --help       ヘルプ
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      TARGET_DIR="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --safe)
      MODE="safe"
      shift
      ;;
    --force)
      MODE="force"
      shift
      ;;
    --sync)
      MODE="sync"
      shift
      ;;
    --overwrite-rdd)
      OVERWRITE_RDD="true"
      shift
      ;;
    --overwrite-ai-task)
      OVERWRITE_AI_TASK="true"
      shift
      ;;
    --no-backup)
      BACKUP="false"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: 不明な引数: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  echo "ERROR: --target は必須です" >&2
  usage >&2
  exit 2
fi

if [ "${TARGET_DIR:0:1}" != "/" ]; then
  echo "ERROR: --target は絶対パスで指定してください: $TARGET_DIR" >&2
  exit 2
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "ERROR: --target が存在しません: $TARGET_DIR" >&2
  exit 2
fi

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' が必要です" >&2; exit 2; }; }
need rsync
need date

# dry-run 以外では、rsync の出力先（親ディレクトリ）が無いとエラーになる。
# 例: 反映先リポジトリに doc/ が存在しない場合、`doc/ai_guidelines.md` のコピーで失敗する。
ensure_target_parent_dir() {
  local rel_path="$1"

  if [[ "$rel_path" == */ ]]; then
    # ディレクトリの同期先（末尾 /）はディレクトリ自体を作っておく。
    mkdir -p "$TARGET_DIR/$rel_path"
    return 0
  fi

  mkdir -p "$TARGET_DIR/$(dirname -- "$rel_path")"
}

# 反映対象（AIテンプレとして必要最小）
INCLUDES=(
  "CLAUDE.md"
  ".cursorrules"
  ".claude/"
  "doc/ai_guidelines.md"
  # RDDは基本的に各プロジェクト固有。初回導入（未存在）だけ反映する。
  "doc/rdd.md"
  # ai-task は運用中に中身が増えるため、基本は初回導入（未存在）だけ反映する。
  "ai-task/"
)

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$TARGET_DIR/.ai-template-backup/$timestamp"

if [ "$BACKUP" = "true" ] && [ "$DRY_RUN" = "false" ]; then
  mkdir -p "$backup_dir"
  for p in "${INCLUDES[@]}"; do
    src="$TARGET_DIR/$p"
    if [ -e "$src" ]; then
      mkdir -p "$backup_dir/$(dirname -- "$p")"
      # バックアップは「いまあるものを退避」できれば十分。失敗しても進められるようにする。
      rsync -a -- "$src" "$backup_dir/$p" >/dev/null 2>&1 || true
    fi
  done
  echo "バックアップ作成: $backup_dir"
fi

RSYNC_FLAGS=(-a)
if [ "$DRY_RUN" = "true" ]; then
  RSYNC_FLAGS+=("--dry-run")
fi

case "$MODE" in
  safe)
    RSYNC_FLAGS+=("--ignore-existing")
    ;;
  force)
    # 既存を上書きする（削除はしない）
    ;;
  sync)
    RSYNC_FLAGS+=("--delete")
    ;;
  *)
    echo "ERROR: 不正なMODE: $MODE" >&2
    exit 2
    ;;
esac

echo "テンプレート: $TEMPLATE_ROOT"
echo "反映先:       $TARGET_DIR"
echo "モード:       $MODE"
echo "overwrite-rdd: $OVERWRITE_RDD"
echo "overwrite-ai-task: $OVERWRITE_AI_TASK"
echo "対象:         ${INCLUDES[*]}"
echo

for p in "${INCLUDES[@]}"; do
  # doc/rdd.md と ai-task/ は「プロジェクト所有」の色が強いので、
  # デフォルトでは上書きしない（安全側）。必要な場合だけ明示フラグで上書きする。
  EXTRA_FLAGS=()
  if [ "$p" = "doc/rdd.md" ] && [ "$OVERWRITE_RDD" != "true" ]; then
    EXTRA_FLAGS+=("--ignore-existing")
  fi
  if [ "$p" = "ai-task/" ] && [ "$OVERWRITE_AI_TASK" != "true" ]; then
    EXTRA_FLAGS+=("--ignore-existing")
  fi

  # 実反映時のみ、出力先ディレクトリを事前作成して rsync エラーを防ぐ。
  if [ "$DRY_RUN" = "false" ]; then
    ensure_target_parent_dir "$p"
  fi

  rsync "${RSYNC_FLAGS[@]}" \
    "${EXTRA_FLAGS[@]}" \
    --exclude ".git/" \
    --exclude "node_modules/" \
    --exclude "dist/" \
    --exclude "build/" \
    --exclude ".next/" \
    --exclude "out/" \
    --exclude "coverage/" \
    --exclude ".venv/" \
    --exclude "vendor/" \
    --exclude ".cache/" \
    --exclude "target/" \
    -- "$TEMPLATE_ROOT/$p" "$TARGET_DIR/$p"
done

echo
if [ "$DRY_RUN" = "true" ]; then
  echo "dry-run 完了（実際の反映は行っていません）"
else
  echo "反映完了"
fi

