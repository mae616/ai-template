# 実行方法
# chmod +x scripts/check_public_quick.sh
# BASE=origin/main scripts/check_public_quick.sh

# 成果物: public_risk_report.md（Markdownレポート）
# CI向け: ヒットあり→終了コード1で落ちる
# ヒットした場合は、public_risk_hits.txt を参照してください。

#!/usr/bin/env bash
set -euo pipefail

# ==== 設定 ====
BASE="${BASE:-origin/main}"              # 比較ブランチ（環境変数で上書き可）
REPORT_MD="${REPORT_MD:-public_risk_report.md}"
TMP_HITS="${TMP_HITS:-/tmp/public_risk_hits.txt}"
EXCLUDES_REGEX='(^|/)(node_modules|dist|build|\.next|out|coverage|\.venv|vendor|\.cache|target|\.git)/'

# 依存確認
need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' が必要です" >&2; exit 2; }; }
need git
need rg
need file

git fetch --quiet || true

# 差分ファイル（追加/更新）
CHANGED=$(git diff --diff-filter=AM --name-only "$BASE"...HEAD || true)

if [ -z "$CHANGED" ]; then
  echo "差分なし。公開リスクなしと判断（差分スコープ）"
  echo -e "# 公開前クイックスキャン結果\n\n- 対象差分: 0 ファイル\n- リスク検出: 0\n" > "$REPORT_MD"
  exit 0
fi

# 除外 + テキスト判定
mapfile -t TEXT_FILES < <(
  echo "$CHANGED" \
  | grep -Ev "$EXCLUDES_REGEX" \
  | xargs -r file --mime 2>/dev/null \
  | awk -F: '$2 ~ /text/ {print $1}'
)

if [ "${#TEXT_FILES[@]}" -eq 0 ]; then
  echo "差分はあるがテキストファイルがありません"
  echo -e "# 公開前クイックスキャン結果\n\n- 対象差分: $(echo "$CHANGED" | wc -l) ファイル\n- テキスト対象: 0\n" > "$REPORT_MD"
  exit 0
fi

# 高速プリチェック（代表的な秘密/個人情報パターン）
: > "$TMP_HITS"
rg -n --no-messages -S \
  -e '-----BEGIN (?:RSA|DSA|EC|OPENSSH) PRIVATE KEY-----' \
  -e 'AKIA[0-9A-Z]{16}' \
  -e 'ASIA[0-9A-Z]{16}' \
  -e 'aws_secret_access_key|aws_access_key_id' \
  -e 'AIza[0-9A-Za-z_\-]{35}' \
  -e 'ghp_[A-Za-z0-9]{36}' \
  -e 'xox[abpr]-[A-Za-z0-9-]+' \
  -e 'sk-[A-Za-z0-9]{20,}' \
  -e '(?i)\bapi[_-]?key\s*[:=]\s*["\047]?[A-Za-z0-9\-_]{16,}["\047]?' \
  -e '(?i)\bsecret[_-]?key\s*[:=]\s*["\047]?[A-Za-z0-9\-_]{16,}["\047]?' \
  -e '(?i)\bpassword\s*[:=]\s*["\047].{6,}["\047]' \
  -e '\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b' \
  -e '(?i)BEGIN CERTIFICATE|PRIVATE KEY|JWT' \
  -g '!.lock' -g '!*.min.*' -g '!*snapshot*' \
  -- "${TEXT_FILES[@]}" | tee -a "$TMP_HITS" >/dev/null || true

HIT_COUNT=$(wc -l < "$TMP_HITS" | tr -d '[:space:]')
DIFF_COUNT=${#TEXT_FILES[@]}

# gitleaks があればヒットファイルのみ詳細チェック
GITLEAKS_JSON=""
if command -v gitleaks >/dev/null 2>&1; then
  if [ "$HIT_COUNT" -gt 0 ]; then
    GITLEAKS_JSON="/tmp/gitleaks_report.json"
    gitleaks detect \
      --no-banner \
      --source . \
      --redact \
      --report-format=json \
      --report-path="$GITLEAKS_JSON" \
      --log-opts="$BASE...HEAD" \
      >/dev/null || true
  fi
fi

# ざっくりMarkdown出力（スニペットは伏字）
{
  echo "# 公開前クイックスキャン結果"
  echo
  echo "- 比較範囲: \`$BASE...HEAD\`"
  echo "- 差分テキスト対象: $DIFF_COUNT ファイル"
  echo "- プリチェック検出: $HIT_COUNT 件"
  if [ -n "$GITLEAKS_JSON" ] && [ -s "$GITLEAKS_JSON" ]; then
    echo "- gitleaks レポート: \`$GITLEAKS_JSON\`"
  fi
  echo
  if [ "$HIT_COUNT" -gt 0 ]; then
    echo "## ⚠️ 要確認（プリチェック一致行）"
    echo
    awk -F: '{f=$1; sub(/^.*\//,"",f); print "- " $1 ":" $2 " → **パターン一致**（スニペット非表示）"}' "$TMP_HITS" | sort -u
    echo
    echo "### 推奨アクション"
    echo "- 秘密情報は即削除し、**新しい値にローテーション**"
    echo "- テストデータは \`fixtures|sample|example|dummy|test\` 配下へ隔離＋ダミー化"
    echo "- さらに詳細が必要なら \`trufflehog\` や履歴スキャンを限定範囲で実行"
  else
    echo "## ✅ 差分内に公開リスクは見つかりませんでした"
  fi
} > "$REPORT_MD"

# 退出コード: ヒット有なら1で落としてCI抑止
if [ "$HIT_COUNT" -gt 0 ]; then
  echo "リスク候補あり: $HIT_COUNT 件。詳細は $REPORT_MD を参照"
  exit 1
else
  echo "問題なし: $REPORT_MD"
  exit 0
fi
