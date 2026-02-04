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

# 6. TIL抽出指示を出力（公式 Stop 出力形式）
REASON="この会話でWebSearch/WebFetchを使った調査を行いました。学びをTILメモとして記録します。

以下の手順で実行してください:
1. 会話で得られた新しい知識・発見を特定
2. TIL保存先ディレクトリを検出 (src/content/til/ → content/til/ → til/)
3. 見つからない場合はユーザーに保存先を確認
4. frontmatter付きMarkdownファイルとして保存
5. 保存結果を報告

ユーザーが不要と判断した場合はスキップしてください。"

jq -n \
  --arg reason "$REASON" \
  '{
    "decision": "block",
    "reason": $reason
  }'

exit 0
