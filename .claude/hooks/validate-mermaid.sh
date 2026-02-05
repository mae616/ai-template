#!/bin/bash
# PostToolUse (Write|Edit) 後に Markdown ファイルの Mermaid 構文を検証
# 目的: 崩れた図をコミット前に検出

FILE_PATH="$CLAUDE_TOOL_ARG_FILE_PATH"

# Markdownファイル以外は対象外
if [[ ! "$FILE_PATH" =~ \.md$ ]]; then
  exit 0
fi

# ファイルが存在しない場合は終了
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# Mermaidブロックを抽出して検証
MERMAID_BLOCKS=$(grep -n '```mermaid' "$FILE_PATH" | cut -d: -f1)

if [[ -z "$MERMAID_BLOCKS" ]]; then
  exit 0
fi

echo "🔍 Mermaid構文チェック: $FILE_PATH"

# mmdc（mermaid-cli）が利用可能か確認
if command -v mmdc &> /dev/null || npx -y @mermaid-js/mermaid-cli --version &> /dev/null 2>&1; then
  # 一時ファイルにMermaidブロックを抽出して検証
  TEMP_DIR=$(mktemp -d)
  BLOCK_NUM=0
  HAS_ERROR=0

  # awkでMermaidブロックを抽出
  awk '/```mermaid/,/```/' "$FILE_PATH" | while read -r line; do
    if [[ "$line" == '```mermaid' ]]; then
      BLOCK_NUM=$((BLOCK_NUM + 1))
      TEMP_FILE="$TEMP_DIR/block_$BLOCK_NUM.mmd"
      continue
    fi
    if [[ "$line" == '```' ]]; then
      # 検証実行
      if [[ -f "$TEMP_FILE" ]]; then
        if ! npx -y @mermaid-js/mermaid-cli -i "$TEMP_FILE" -o /dev/null 2>/dev/null; then
          echo "⚠️  構文エラー: Mermaidブロック #$BLOCK_NUM"
          HAS_ERROR=1
        fi
      fi
      continue
    fi
    if [[ -n "$TEMP_FILE" ]]; then
      echo "$line" >> "$TEMP_FILE"
    fi
  done

  rm -rf "$TEMP_DIR"

  if [[ $HAS_ERROR -eq 0 ]]; then
    echo "✅ Mermaid構文: OK"
  fi
else
  # mmdc が無い場合は簡易チェック（よくある構文エラーパターン）
  echo "💡 mermaid-cli 未インストール（簡易チェックのみ）"

  # 基本的な構文パターンチェック
  if grep -q '```mermaid' "$FILE_PATH"; then
    # 閉じタグの確認
    OPEN_COUNT=$(grep -c '```mermaid' "$FILE_PATH")
    CLOSE_COUNT=$(grep -c '```$' "$FILE_PATH")

    if [[ $OPEN_COUNT -gt $CLOSE_COUNT ]]; then
      echo "⚠️  Mermaidブロックの閉じタグが不足している可能性"
    else
      echo "✅ 簡易チェック: OK（詳細検証には mermaid-cli が必要）"
    fi
  fi
fi
