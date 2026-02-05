#!/usr/bin/env bash
set -euo pipefail

# ai-template の共通部分を ~/.claude に適用するスクリプト。
# - グローバルなスキル、設定、CLAUDE.md を更新
# - 既存ファイルはバックアップを作成してから上書き
#
# 使い方:
#   scripts/apply_global.sh --dry-run
#   scripts/apply_global.sh
#
# 想定:
# - このスクリプトは ai-template リポジトリ内から実行する
# - ~/.claude ディレクトリが存在する（Claude Code インストール済み）

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
GLOBAL_DIR="$HOME/.claude"

DRY_RUN="false"
BACKUP="true"
SKIP_SKILLS="false"
SKIP_SETTINGS="false"
SKIP_CLAUDE_MD="false"
ALL_SKILLS="false"

usage() {
  cat <<'USAGE'
使い方:
  scripts/apply_global.sh [オプション]

オプション:
  --dry-run         実際には書き込まず、差分だけ表示
  --no-backup       上書き前バックアップを作成しない（非推奨）
  --all-skills      全スキルを適用（手順系含む）
  --skip-skills     スキルの適用をスキップ
  --skip-settings   settings.local.json の適用をスキップ
  --skip-claude-md  CLAUDE.md の適用をスキップ
  -h, --help        ヘルプ

適用対象:
  1. ~/.claude/skills/     スキル（デフォルト: 判断軸のみ、--all-skills: 全て）
  2. ~/.claude/settings.local.json  permissions のマージ
  3. ~/.claude/CLAUDE.md   グローバル設定（全プロジェクト共通）

注意:
  - デフォルトは判断軸スキル（user-invocable: false）のみ
  - --all-skills で手順系（user-invocable: true）も含む
  - settings.local.json の permissions は追加のみ（既存は削除しない）
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --no-backup)
      BACKUP="false"
      shift
      ;;
    --skip-skills)
      SKIP_SKILLS="true"
      shift
      ;;
    --skip-settings)
      SKIP_SETTINGS="true"
      shift
      ;;
    --skip-claude-md)
      SKIP_CLAUDE_MD="true"
      shift
      ;;
    --all-skills)
      ALL_SKILLS="true"
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

if [ ! -d "$GLOBAL_DIR" ]; then
  echo "ERROR: ~/.claude が存在しません。Claude Code をインストールしてください。" >&2
  exit 2
fi

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' が必要です" >&2; exit 2; }; }
need rsync
need date

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$GLOBAL_DIR/.ai-template-backup/$timestamp"

echo "=========================================="
echo "ai-template グローバル適用"
echo "=========================================="
echo "テンプレート: $TEMPLATE_ROOT"
echo "適用先:       $GLOBAL_DIR"
echo "dry-run:      $DRY_RUN"
echo

# ------------------------------
# 1. 判断軸スキル（user-invocable: false）の適用
# ------------------------------
if [ "$SKIP_SKILLS" = "false" ]; then
  echo "--- スキルの適用 ---"

  # スキルを抽出（--all-skills: 全て、デフォルト: 判断軸のみ）
  TARGET_SKILLS=()
  for skill_dir in "$TEMPLATE_ROOT/.claude/skills/"*/; do
    skill_name=$(basename "$skill_dir")
    skill_md="$skill_dir/SKILL.md"

    if [ -f "$skill_md" ]; then
      # user-invocable: true があるかチェック
      is_procedure=$(grep -q "user-invocable: true" "$skill_md" 2>/dev/null && echo "true" || echo "false")

      if [ "$ALL_SKILLS" = "true" ]; then
        # 全スキル適用
        TARGET_SKILLS+=("$skill_name")
        if [ "$is_procedure" = "true" ]; then
          echo "  [ADD]  $skill_name (手順系)"
        else
          echo "  [ADD]  $skill_name (判断軸)"
        fi
      else
        # 判断軸のみ
        if [ "$is_procedure" = "true" ]; then
          echo "  [SKIP] $skill_name (手順系 → --all-skills で適用可)"
        else
          TARGET_SKILLS+=("$skill_name")
          echo "  [ADD]  $skill_name (判断軸)"
        fi
      fi
    fi
  done

  if [ ${#TARGET_SKILLS[@]} -gt 0 ]; then
    if [ "$DRY_RUN" = "false" ]; then
      # バックアップ
      if [ "$BACKUP" = "true" ]; then
        for skill_name in "${TARGET_SKILLS[@]}"; do
          if [ -d "$GLOBAL_DIR/skills/$skill_name" ]; then
            mkdir -p "$backup_dir/skills"
            cp -r "$GLOBAL_DIR/skills/$skill_name" "$backup_dir/skills/" 2>/dev/null || true
          fi
        done
      fi

      # 適用
      mkdir -p "$GLOBAL_DIR/skills"
      for skill_name in "${TARGET_SKILLS[@]}"; do
        rsync -a --delete \
          "$TEMPLATE_ROOT/.claude/skills/$skill_name/" \
          "$GLOBAL_DIR/skills/$skill_name/"
      done
      echo "  → 適用完了"
    else
      echo "  → [dry-run] 実際には適用しません"
    fi
  else
    echo "  適用対象のスキルがありません"
  fi
  echo
fi

# ------------------------------
# 2. settings.local.json の permissions マージ
# ------------------------------
if [ "$SKIP_SETTINGS" = "false" ]; then
  echo "--- settings.local.json の適用 ---"

  TEMPLATE_SETTINGS="$TEMPLATE_ROOT/.claude/settings.local.json"
  GLOBAL_SETTINGS="$GLOBAL_DIR/settings.local.json"

  if [ -f "$TEMPLATE_SETTINGS" ]; then
    if [ "$DRY_RUN" = "false" ]; then
      # バックアップ
      if [ "$BACKUP" = "true" ] && [ -f "$GLOBAL_SETTINGS" ]; then
        mkdir -p "$backup_dir"
        cp "$GLOBAL_SETTINGS" "$backup_dir/settings.local.json" 2>/dev/null || true
      fi

      if [ -f "$GLOBAL_SETTINGS" ]; then
        # 既存がある場合はマージ（jq使用）
        if command -v jq >/dev/null 2>&1; then
          # 既存設定を保持しつつ、permissions.allow と permissions.ask をマージ（重複排除）
          MERGED=$(jq -s '
            .[0] as $old |
            .[1] as $new |
            ($old.permissions.allow // []) as $old_allow |
            ($old.permissions.ask // []) as $old_ask |
            ($new.permissions.allow // []) as $new_allow |
            ($new.permissions.ask // []) as $new_ask |
            # 既存設定をベースに、テンプレートの設定をマージ（permissionsは特別扱い）
            ($old * $new) * {
              permissions: {
                allow: (($old_allow + $new_allow) | unique),
                ask: (($old_ask + $new_ask) | unique)
              }
            }
          ' "$GLOBAL_SETTINGS" "$TEMPLATE_SETTINGS")
          echo "$MERGED" > "$GLOBAL_SETTINGS"
          echo "  → マージ完了（jq使用）"
        else
          # jqがない場合は上書き（警告付き）
          echo "  [WARN] jq がインストールされていないため、上書きします"
          cp "$TEMPLATE_SETTINGS" "$GLOBAL_SETTINGS"
          echo "  → 上書き完了"
        fi
      else
        # 新規作成
        cp "$TEMPLATE_SETTINGS" "$GLOBAL_SETTINGS"
        echo "  → 新規作成完了"
      fi
    else
      echo "  テンプレート: $TEMPLATE_SETTINGS"
      echo "  適用先:       $GLOBAL_SETTINGS"
      echo "  → [dry-run] 実際には適用しません"
    fi
  else
    echo "  テンプレートに settings.local.json がありません"
  fi
  echo
fi

# ------------------------------
# 3. CLAUDE.md の適用
# ------------------------------
if [ "$SKIP_CLAUDE_MD" = "false" ]; then
  echo "--- CLAUDE.md の適用 ---"

  TEMPLATE_CLAUDE_MD="$TEMPLATE_ROOT/CLAUDE.md"
  GLOBAL_CLAUDE_MD="$GLOBAL_DIR/CLAUDE.md"

  if [ -f "$TEMPLATE_CLAUDE_MD" ]; then
    if [ "$DRY_RUN" = "false" ]; then
      # バックアップ
      if [ "$BACKUP" = "true" ] && [ -f "$GLOBAL_CLAUDE_MD" ]; then
        mkdir -p "$backup_dir"
        cp "$GLOBAL_CLAUDE_MD" "$backup_dir/CLAUDE.md" 2>/dev/null || true
      fi

      # 適用
      cp "$TEMPLATE_CLAUDE_MD" "$GLOBAL_CLAUDE_MD"
      echo "  → 適用完了"
    else
      echo "  テンプレート: $TEMPLATE_CLAUDE_MD"
      echo "  適用先:       $GLOBAL_CLAUDE_MD"
      echo "  → [dry-run] 実際には適用しません"
    fi
  else
    echo "  テンプレートに CLAUDE.md がありません"
  fi
  echo
fi

# ------------------------------
# 完了
# ------------------------------
echo "=========================================="
if [ "$DRY_RUN" = "true" ]; then
  echo "dry-run 完了（実際の適用は行っていません）"
else
  if [ "$BACKUP" = "true" ] && [ -d "$backup_dir" ]; then
    echo "バックアップ: $backup_dir"
  fi
  echo "適用完了"
fi
echo
echo "次のステップ:"
echo "  - Claude Code を再起動してスキルを反映"
echo "  - /setup でプロジェクト固有の設定を読み込み"
