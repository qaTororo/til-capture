#!/bin/bash
set -euo pipefail

HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd')

# TILディレクトリ検出
TIL_DIR=""
for dir in "src/content/til" "content/til" "til"; do
  if [[ -d "${CWD}/${dir}" ]]; then
    TIL_DIR="${CWD}/${dir}"
    break
  fi
done

# TILディレクトリが見つからない場合は何もしない
if [[ -z "$TIL_DIR" ]]; then
  exit 0
fi

# .mdファイル数カウント
COUNT=$(find "$TIL_DIR" -name "*.md" -type f 2>/dev/null | wc -l)

# コンテキストに注入（公式 SessionStart 出力形式）
jq -n \
  --arg ctx "TIL stock: ${COUNT} entries (${TIL_DIR})" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "SessionStart",
      "additionalContext": $ctx
    }
  }'

exit 0
