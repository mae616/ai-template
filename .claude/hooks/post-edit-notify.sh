#!/bin/bash
# PostToolUse (Write|Edit) 後に実行されるフック
# 目的: 重要ファイル編集時にコミットを促す

FILE_PATH="$CLAUDE_TOOL_ARG_FILE_PATH"

# デザイン/ドキュメント関連ファイルの場合に通知
if [[ "$FILE_PATH" == *"doc/input/design/"* ]] || [[ "$FILE_PATH" == *"doc/generated/"* ]]; then
  echo "📝 デザイン/ドキュメントファイルを編集しました: $FILE_PATH"
  echo "💡 区切りの良いタイミングでコミットを検討してください"
fi
