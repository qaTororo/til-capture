#!/bin/bash
set -euo pipefail

# 依存コマンドチェック
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: til-capture: jq is required but not installed" >&2
  exit 1
fi

HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd')

# CWD の安全性検証
if [[ -z "$CWD" || "$CWD" == "null" || ! "$CWD" =~ ^/ ]] || [[ "$CWD" =~ \.\. ]]; then
  CWD=""
fi

# --- config.json 読み取り ---
CONFIG_FILE="${HOME}/.config/til-capture/config.json"
DEFAULT_TIL_DIR=""
if [[ -f "$CONFIG_FILE" ]]; then
  if ! DEFAULT_TIL_DIR=$(jq -r '.defaultTilDir // empty' "$CONFIG_FILE" 2>/dev/null); then
    DEFAULT_TIL_DIR=""
  fi
  # パストラバーサル・相対パスの排除（不正値は静かにフォールバック）
  if [[ -n "$DEFAULT_TIL_DIR" ]]; then
    if [[ ! "$DEFAULT_TIL_DIR" =~ ^/ ]] || [[ "$DEFAULT_TIL_DIR" =~ \.\. ]]; then
      DEFAULT_TIL_DIR=""
    fi
  fi
fi

# --- .md ファイル数カウント（上限1001件で打ち切り、性能対策） ---
count_md_files() {
  local dir="$1"
  local count
  count=$(
    set +o pipefail
    find "$dir" -name "*.md" -type f 2>/dev/null | head -n 1001 | wc -l
  ) || count=0
  # wc -l の出力から空白を除去
  echo "${count// /}"
}

# --- CWD 内 TIL ディレクトリ検出 ---
TIL_DIR=""
if [[ -n "$CWD" ]]; then
  for dir in "src/content/til" "content/til" "til"; do
    if [[ -d "${CWD}/${dir}" ]]; then
      TIL_DIR="${CWD}/${dir}"
      break
    fi
  done
fi

# --- ステータス表示（常時出力） ---
if [[ -n "$TIL_DIR" ]]; then
  COUNT=$(count_md_files "$TIL_DIR")
  if [[ "$COUNT" -gt 1000 ]]; then
    STATUS="TIL auto-capture: ON (WebSearch/WebFetch) | Stock: 1000+ entries (${TIL_DIR})"
  else
    STATUS="TIL auto-capture: ON (WebSearch/WebFetch) | Stock: ${COUNT} entries (${TIL_DIR})"
  fi
elif [[ -n "$DEFAULT_TIL_DIR" ]]; then
  if [[ -d "$DEFAULT_TIL_DIR" ]]; then
    COUNT=$(count_md_files "$DEFAULT_TIL_DIR")
    if [[ "$COUNT" -gt 1000 ]]; then
      STATUS="TIL auto-capture: ON (WebSearch/WebFetch) | Stock: 1000+ entries (${DEFAULT_TIL_DIR})"
    else
      STATUS="TIL auto-capture: ON (WebSearch/WebFetch) | Stock: ${COUNT} entries (${DEFAULT_TIL_DIR})"
    fi
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
