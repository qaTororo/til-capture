#!/bin/bash
set -euo pipefail

HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd')

# --- config.json 読み取り ---
CONFIG_FILE="${HOME}/.config/til-capture/config.json"
DEFAULT_TIL_DIR=""
if [[ -f "$CONFIG_FILE" ]]; then
  DEFAULT_TIL_DIR=$(jq -r '.defaultTilDir // empty' "$CONFIG_FILE" 2>/dev/null || true)
fi

# --- CWD 内 TIL ディレクトリ検出 ---
TIL_DIR=""
for dir in "src/content/til" "content/til" "til"; do
  if [[ -d "${CWD}/${dir}" ]]; then
    TIL_DIR="${CWD}/${dir}"
    break
  fi
done

# --- ステータス表示（常時出力） ---
if [[ -n "$TIL_DIR" ]]; then
  COUNT=$(find "$TIL_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
  STATUS="TIL auto-capture: ON (WebSearch/WebFetch) | Stock: ${COUNT} entries (${TIL_DIR})"
elif [[ -n "$DEFAULT_TIL_DIR" ]]; then
  if [[ -d "$DEFAULT_TIL_DIR" ]]; then
    COUNT=$(find "$DEFAULT_TIL_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
    STATUS="TIL auto-capture: ON (WebSearch/WebFetch) | Stock: ${COUNT} entries (${DEFAULT_TIL_DIR})"
  else
    STATUS="TIL auto-capture: ON (WebSearch/WebFetch) | Save to: ${DEFAULT_TIL_DIR} (will ask)"
  fi
else
  STATUS="TIL auto-capture: ON (WebSearch/WebFetch) | Save to: ~/til/ (will ask, configurable via ~/.config/til-capture/config.json)"
fi

jq -n \
  --arg ctx "$STATUS" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "SessionStart",
      "additionalContext": $ctx
    }
  }'

exit 0
