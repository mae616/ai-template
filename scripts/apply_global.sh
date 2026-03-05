#!/usr/bin/env bash
set -euo pipefail

# ai-template の共通部分を ~/.claude に適用するスクリプト。
# - グローバルなスキル、設定、CLAUDE.md を更新
# - 既存ファイルはバックアップを作成してから上書き
#
# 使い方:
#   scripts/apply_global.sh --dry-run
#   scripts/apply_global.sh

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
GLOBAL_DIR="$HOME/.claude"

DRY_RUN="false"
BACKUP="true"
SKIP_SKILLS="false"
SKIP_HOOKS="false"
SKIP_RULES="false"
SKIP_SETTINGS="false"
SKIP_CLAUDE_MD="false"
ALL_SKILLS="false"

usage() {
  cat <<'USAGE'
使い方:
  scripts/apply_global.sh [オプション]

オプション:
  --dry-run           実際には書き込まず、差分だけ表示
  --no-backup         上書き前バックアップを作成しない（非推奨）
  --all-skills        全スキルを適用（手順系含む）
  --skip-skills       スキルの適用をスキップ
  --skip-hooks        hooks/ の適用をスキップ
  --skip-rules        rules/ の適用をスキップ
  --skip-settings     settings.json の適用をスキップ
  --skip-claude-md    CLAUDE.md の適用をスキップ
  -h, --help          ヘルプ

適用対象:
  1. ~/.claude/skills/             スキル（デフォルト: 判断軸のみ、--all-skills: 全て）
  2. ~/.claude/hooks/              フック（シェルスクリプト）
  3. ~/.claude/rules/              運用ルール（自動適用される .md）
  4. ~/.claude/settings.json       permissions + hooks のマージ
  5. ~/.claude/CLAUDE.md           グローバル設定（全プロジェクト共通）

注意:
  - デフォルトは判断軸スキル（user-invocable: false）のみ
  - --all-skills で手順系（user-invocable: true）も含む
  - settings.json の permissions は追加のみ（既存は削除しない）
  - settings.json の hooks は上書き（hooks構造はマージが複雑なため）
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)          DRY_RUN="true"; shift ;;
    --no-backup)        BACKUP="false"; shift ;;
    --skip-skills)      SKIP_SKILLS="true"; shift ;;
    --skip-hooks)       SKIP_HOOKS="true"; shift ;;
    --skip-rules)       SKIP_RULES="true"; shift ;;
    --skip-settings)    SKIP_SETTINGS="true"; shift ;;
    --skip-claude-md)   SKIP_CLAUDE_MD="true"; shift ;;
    --all-skills)       ALL_SKILLS="true"; shift ;;
    -h|--help)          usage; exit 0 ;;
    *)                  echo "ERROR: 不明な引数: $1" >&2; usage >&2; exit 2 ;;
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

# バックアップ: ファイルまたはディレクトリを退避
backup_item() {
  local src="$1"
  local dest="$2"
  [ "$BACKUP" = "true" ] && [ -e "$src" ] || return 0
  mkdir -p "$(dirname "$dest")"
  cp -r "$src" "$dest" 2>/dev/null || true
}

# settings.json のマージ適用
# $1: テンプレート側パス  $2: 適用先パス  $3: jqマージ式
merge_settings() {
  local template="$1" target="$2" jq_expr="$3" label
  label="$(basename "$target")"

  if [ ! -f "$template" ]; then
    echo "  テンプレートに $label がありません"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "  テンプレート: $template"
    echo "  適用先:       $target"
    echo "  → [dry-run] 実際には適用しません"
    return 0
  fi

  backup_item "$target" "$backup_dir/$label"

  if [ ! -f "$target" ]; then
    cp "$template" "$target"
    echo "  → 新規作成完了"
    return 0
  fi

  if command -v jq >/dev/null 2>&1; then
    jq -s "$jq_expr" "$target" "$template" > "${target}.tmp" \
      && mv "${target}.tmp" "$target"
    echo "  → マージ完了（jq使用）"
  else
    echo "  [WARN] jq がインストールされていないため、上書きします"
    cp "$template" "$target"
    echo "  → 上書き完了"
  fi
}

echo "=========================================="
echo "ai-template グローバル適用"
echo "=========================================="
echo "テンプレート: $TEMPLATE_ROOT"
echo "適用先:       $GLOBAL_DIR"
echo "dry-run:      $DRY_RUN"
echo

# --- 1. スキルの適用 ---
if [ "$SKIP_SKILLS" = "false" ]; then
  echo "--- スキルの適用 ---"
  TARGET_SKILLS=()

  for skill_dir in "$TEMPLATE_ROOT/.claude/skills/"*/; do
    skill_name=$(basename "$skill_dir")
    skill_md="$skill_dir/SKILL.md"
    [ -f "$skill_md" ] || continue

    is_procedure=$(grep -q "user-invocable: true" "$skill_md" 2>/dev/null && echo "true" || echo "false")

    if [ "$ALL_SKILLS" = "true" ] || [ "$is_procedure" = "false" ]; then
      TARGET_SKILLS+=("$skill_name")
      label=$( [ "$is_procedure" = "true" ] && echo "手順系" || echo "判断軸" )
      echo "  [ADD]  $skill_name ($label)"
    else
      echo "  [SKIP] $skill_name (手順系 → --all-skills で適用可)"
    fi
  done

  if [ ${#TARGET_SKILLS[@]} -gt 0 ] && [ "$DRY_RUN" = "false" ]; then
    for skill_name in "${TARGET_SKILLS[@]}"; do
      backup_item "$GLOBAL_DIR/skills/$skill_name" "$backup_dir/skills/$skill_name"
    done
    mkdir -p "$GLOBAL_DIR/skills"
    for skill_name in "${TARGET_SKILLS[@]}"; do
      rsync -a --delete \
        "$TEMPLATE_ROOT/.claude/skills/$skill_name/" \
        "$GLOBAL_DIR/skills/$skill_name/"
    done
    echo "  → 適用完了"
  elif [ ${#TARGET_SKILLS[@]} -eq 0 ]; then
    echo "  適用対象のスキルがありません"
  else
    echo "  → [dry-run] 実際には適用しません"
  fi
  echo
fi

# --- 2. hooks/ の適用 ---
if [ "$SKIP_HOOKS" = "false" ]; then
  echo "--- hooks/ の適用 ---"
  TEMPLATE_HOOKS="$TEMPLATE_ROOT/.claude/hooks"

  if [ -d "$TEMPLATE_HOOKS" ]; then
    for hook_file in "$TEMPLATE_HOOKS"/*; do
      [ -f "$hook_file" ] && echo "  [ADD] $(basename "$hook_file")"
    done

    if [ "$DRY_RUN" = "false" ]; then
      backup_item "$GLOBAL_DIR/hooks" "$backup_dir/hooks"
      mkdir -p "$GLOBAL_DIR/hooks"
      rsync -a --delete "$TEMPLATE_HOOKS/" "$GLOBAL_DIR/hooks/"
      echo "  → 適用完了"
    else
      echo "  → [dry-run] 実際には適用しません"
    fi
  else
    echo "  テンプレートに hooks/ がありません"
  fi
  echo
fi

# --- 3. rules/ の適用 ---
if [ "$SKIP_RULES" = "false" ]; then
  echo "--- rules/ の適用 ---"
  TEMPLATE_RULES="$TEMPLATE_ROOT/.claude/rules"

  if [ -d "$TEMPLATE_RULES" ]; then
    for rule_file in "$TEMPLATE_RULES"/*.md; do
      [ -f "$rule_file" ] && echo "  [ADD] $(basename "$rule_file")"
    done

    if [ "$DRY_RUN" = "false" ]; then
      backup_item "$GLOBAL_DIR/rules" "$backup_dir/rules"
      mkdir -p "$GLOBAL_DIR/rules"
      rsync -a --delete "$TEMPLATE_RULES/" "$GLOBAL_DIR/rules/"
      echo "  → 適用完了"
    else
      echo "  → [dry-run] 実際には適用しません"
    fi
  else
    echo "  テンプレートに rules/ がありません"
  fi
  echo
fi

# --- 4. settings.json の適用（permissions.allow + ask マージ、hooks 上書き） ---
if [ "$SKIP_SETTINGS" = "false" ]; then
  echo "--- settings.json の適用 ---"
  merge_settings \
    "$TEMPLATE_ROOT/.claude/settings.json" \
    "$GLOBAL_DIR/settings.json" \
    '.[0] as $old | .[1] as $new |
     ($old * $new) * {
       permissions: {
         allow: ((($old.permissions.allow // []) + ($new.permissions.allow // [])) | unique),
         ask: ((($old.permissions.ask // []) + ($new.permissions.ask // [])) | unique)
       }
     }'
  echo
fi

# --- 5. CLAUDE.md の適用 ---
if [ "$SKIP_CLAUDE_MD" = "false" ]; then
  echo "--- CLAUDE.md の適用 ---"
  TEMPLATE_CLAUDE_MD="$TEMPLATE_ROOT/CLAUDE.md"
  GLOBAL_CLAUDE_MD="$GLOBAL_DIR/CLAUDE.md"

  if [ -f "$TEMPLATE_CLAUDE_MD" ]; then
    if [ "$DRY_RUN" = "false" ]; then
      backup_item "$GLOBAL_CLAUDE_MD" "$backup_dir/CLAUDE.md"
      cp "$TEMPLATE_CLAUDE_MD" "$GLOBAL_CLAUDE_MD"
      echo "  → 適用完了"
    else
      echo "  → [dry-run] 実際には適用しません"
    fi
  else
    echo "  テンプレートに CLAUDE.md がありません"
  fi
  echo
fi

# --- 完了 ---
echo "=========================================="
if [ "$DRY_RUN" = "true" ]; then
  echo "dry-run 完了（実際の適用は行っていません）"
else
  [ "$BACKUP" = "true" ] && [ -d "$backup_dir" ] && echo "バックアップ: $backup_dir"
  echo "適用完了"
fi
echo
echo "次のステップ:"
echo "  - Claude Code を再起動してスキルを反映"
echo "  - /setup でプロジェクト固有の設定を読み込み"
