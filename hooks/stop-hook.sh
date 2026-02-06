#!/bin/bash
set -euo pipefail

HOOK_INPUT=$(cat)

# 1. 無限ループ防止: stop_hook_active チェック（公式仕様のフィールド）
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id')
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd')
STATE_FILE="/tmp/til-capture-${SESSION_ID}"

# 2. 既にサジェスト済みチェック
if [[ -f "$STATE_FILE" ]]; then
  exit 0
fi

# 3. トランスクリプト存在チェック
if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  exit 0
fi

# 4. WebSearch/WebFetch 使用チェック
if ! grep -q '"WebSearch"\|"WebFetch"' "$TRANSCRIPT_PATH"; then
  exit 0
fi

# 5. 状態ファイル作成（1セッション1回）
touch "$STATE_FILE"

# 6. 保存先を解決（CWD → config → ~/til/）+ 信頼度判定
TIL_DIR=""
TRUSTED=false

# Step 1: CWD 内の既存ディレクトリ → 高信頼
for dir in "src/content/til" "content/til" "til"; do
  if [[ -d "${CWD}/${dir}" ]]; then
    TIL_DIR="${CWD}/${dir}"
    TRUSTED=true
    break
  fi
done

# Step 2: config.json の defaultTilDir → 既存なら高信頼、未存在なら低信頼
if [[ -z "$TIL_DIR" ]]; then
  CONFIG_FILE="${HOME}/.config/til-capture/config.json"
  if [[ -f "$CONFIG_FILE" ]]; then
    TIL_DIR=$(jq -r '.defaultTilDir // empty' "$CONFIG_FILE" 2>/dev/null || true)
    if [[ -n "$TIL_DIR" ]]; then
      if [[ -d "$TIL_DIR" ]]; then
        TRUSTED=true
      fi
      # TIL_DIR は存在しなくても設定値を保持（低信頼で確認付き）
    fi
  fi
fi

# Step 3: フォールバック ~/til/ → 低信頼
if [[ -z "$TIL_DIR" ]]; then
  TIL_DIR="${HOME}/til"
fi

# 7. TIL抽出指示を出力（信頼度に応じてメッセージ分岐）
if [[ "$TRUSTED" == "true" ]]; then
  REASON="この会話でWebSearch/WebFetchを使った調査を行いました。学びをTILメモとして記録します。

保存先: ${TIL_DIR}

以下の手順で実行してください:
1. 会話で得られた新しい知識・発見を特定
2. 保存先ディレクトリ ${TIL_DIR} に保存
3. frontmatter付きMarkdownファイルとして保存
4. 保存結果を報告

ユーザーが不要と判断した場合はスキップしてください。"
else
  REASON="この会話でWebSearch/WebFetchを使った調査を行いました。学びをTILメモとして記録しませんか？

保存先候補: ${TIL_DIR}

このディレクトリはまだ存在しないか、明示的に設定されていません。
ユーザーに保存先を確認してから保存してください。
（~/.config/til-capture/config.json で defaultTilDir を設定すると次回から自動保存されます）

手順:
1. ユーザーに「${TIL_DIR} に保存してよいですか？」と確認
2. 承認されたら mkdir -p でディレクトリを作成し保存
3. 拒否またはスキップされたら何もしない"
fi

jq -n \
  --arg reason "$REASON" \
  '{
    "decision": "block",
    "reason": $reason
  }'

exit 0
