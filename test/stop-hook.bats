#!/usr/bin/env bats

setup() {
  load test-helper
  common_setup
  HOOK_SCRIPT="${PROJECT_ROOT}/hooks/stop-hook.sh"
}

teardown() {
  common_teardown
}

# --- 1. stop_hook_active=true → 早期終了 ---
@test "stop_hook_active=true → 早期終了、出力なし" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "true")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- 2. stop_hook_active=false → 処理続行 ---
@test "stop_hook_active=false → 処理が続行される" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_cwd_til_dir "til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

# --- 3. 状態ファイル既存 → 早期終了 ---
@test "状態ファイルが既に存在 → 早期終了、出力なし" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_state_file "$TEST_SESSION_ID"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- 4. トランスクリプト不在 → 早期終了 ---
@test "トランスクリプトが存在しない → 早期終了、出力なし" {
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "/nonexistent/path.jsonl" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- 5. WebSearch/WebFetch なし → 早期終了 ---
@test "WebSearch/WebFetch未使用 → 早期終了、出力なし" {
  local transcript
  transcript=$(create_transcript)
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- 6. WebSearch あり → ブロック ---
@test "WebSearchあり → decision=block のJSON出力" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_cwd_til_dir "til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.decision == "block"'
}

# --- 7. WebFetch あり → ブロック ---
@test "WebFetchあり → decision=block のJSON出力" {
  local transcript
  transcript=$(create_transcript "WebFetch")
  create_cwd_til_dir "til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.decision == "block"'
}

# --- 8. 状態ファイルが作成される ---
@test "処理実行後に状態ファイルが作成される" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_cwd_til_dir "til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  bash -c "echo '$input' | bash '$HOOK_SCRIPT'" > /dev/null
  local state_file
  state_file=$(get_state_file "$TEST_SESSION_ID")
  [ -f "$state_file" ]
}

# --- 9. 2回目実行 → 状態ファイルで早期終了 ---
@test "2回目の実行 → 状態ファイルにより早期終了" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_cwd_til_dir "til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  # 1回目: 出力あり
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -n "$output" ]

  # 2回目: 出力なし（状態ファイルで早期終了）
  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- 10. CWD に til/ がある → 高信頼 ---
@test "CWD に til/ がある → 高信頼メッセージ" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_cwd_til_dir "til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  [[ "$reason" == *"自動保存"* ]] || [[ "$reason" == *"保存先: ${TEST_CWD}/til"* ]]
}

# --- 11. CWD に content/til/ がある → 高信頼 ---
@test "CWD に content/til/ がある → 高信頼メッセージ" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_cwd_til_dir "content/til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  [[ "$reason" == *"保存先: ${TEST_CWD}/content/til"* ]]
}

# --- 12. CWD に src/content/til/ がある → 高信頼 ---
@test "CWD に src/content/til/ がある → 高信頼メッセージ + 正しいパス" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_cwd_til_dir "src/content/til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  [[ "$reason" == *"保存先: ${TEST_CWD}/src/content/til"* ]]
}

# --- 13. CWD 検出の優先順位 ---
@test "CWD 検出優先順位: src/content/til > content/til > til" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  # 3つ全部作る
  create_cwd_til_dir "til"
  create_cwd_til_dir "content/til"
  create_cwd_til_dir "src/content/til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  [[ "$reason" == *"${TEST_CWD}/src/content/til"* ]]
}

# --- 14. config.json あり + ディレクトリ存在 → 高信頼 ---
@test "config.json指定ディレクトリが存在 → 高信頼メッセージ" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  local config_til_dir="${BATS_TEST_TMPDIR}/custom-til"
  mkdir -p "$config_til_dir"
  create_config "$config_til_dir"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  [[ "$reason" == *"保存先: ${config_til_dir}"* ]]
  # 高信頼メッセージ: "記録します" が含まれる
  [[ "$reason" == *"記録します"* ]]
}

# --- 15. config.json あり + ディレクトリ未存在 → 低信頼 ---
@test "config.json指定ディレクトリが未存在 → 低信頼メッセージ" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_config "/nonexistent/custom-til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  # 低信頼メッセージ: "確認" が含まれる
  [[ "$reason" == *"確認"* ]]
}

# --- 16. config.json なし → フォールバック ~/til/ ---
@test "config.json なし → ~/til/ フォールバック、低信頼" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  [[ "$reason" == *"${HOME}/til"* ]]
  [[ "$reason" == *"確認"* ]]
}

# --- 17. CWD ディレクトリが config より優先 ---
@test "CWD の til/ が config.json より優先される" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_cwd_til_dir "til"
  local config_til_dir="${BATS_TEST_TMPDIR}/config-til"
  mkdir -p "$config_til_dir"
  create_config "$config_til_dir"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  # CWD の til/ が使われる（config のパスではない）
  [[ "$reason" == *"${TEST_CWD}/til"* ]]
}

# --- 18. 高信頼メッセージに保存先パスが含まれる ---
@test "高信頼メッセージに保存先パスが含まれる" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_cwd_til_dir "til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  [[ "$reason" == *"保存先: ${TEST_CWD}/til"* ]]
  [[ "$reason" == *"保存先ディレクトリ ${TEST_CWD}/til"* ]]
}

# --- 19. 低信頼メッセージに保存先パスが含まれる ---
@test "低信頼メッセージに保存先パスが含まれる" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  [[ "$reason" == *"保存先候補: ${HOME}/til"* ]]
  [[ "$reason" == *"${HOME}/til に保存してよいですか"* ]]
}

# --- 20. 必須フィールド欠落 → 早期終了 ---
@test "session_id が空 → 早期終了、出力なし" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  local input
  input=$(jq -n \
    --arg tp "$transcript" \
    --arg cwd "$TEST_CWD" \
    '{
      session_id: "",
      transcript_path: $tp,
      cwd: $cwd,
      stop_hook_active: false
    }')

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- 21. CWD にパストラバーサル → 早期終了 ---
@test "CWD にパストラバーサルを含む → 早期終了" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "/tmp/../etc" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- 22. CWD が相対パス → 早期終了 ---
@test "CWD が相対パス → 早期終了" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "relative/path" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- 23. config.json のパストラバーサル → フォールバック ---
@test "config.json にパストラバーサル → フォールバックで ~/til/" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_config "/tmp/../etc/evil"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  # パストラバーサルが拒否され、フォールバック ~/til/ が使われる
  [[ "$reason" == *"${HOME}/til"* ]]
}

# --- 24. config.json に相対パス → フォールバック ---
@test "config.json に相対パス → フォールバックで ~/til/" {
  local transcript
  transcript=$(create_transcript "WebSearch")
  create_config "relative/til"
  local input
  input=$(generate_stop_hook_input "$TEST_SESSION_ID" "$transcript" "$TEST_CWD" "false")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local reason
  reason=$(echo "$output" | jq -r '.reason')
  [[ "$reason" == *"${HOME}/til"* ]]
}
