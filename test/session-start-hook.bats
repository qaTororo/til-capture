#!/usr/bin/env bats

setup() {
  load test-helper
  common_setup
  HOOK_SCRIPT="${PROJECT_ROOT}/hooks/session-start-hook.sh"
}

teardown() {
  common_teardown
}

# --- 1. CWD に til/ がある → Stock 表示 ---
@test "CWD に til/ がある → Stock 表示" {
  create_cwd_til_dir "til"
  add_md_files "${TEST_CWD}/til" "2024-01-01-test.md"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"Stock: 1 entries"* ]]
}

# --- 2. CWD に content/til/ がある → Stock 表示 ---
@test "CWD に content/til/ がある → 正しいカウント" {
  create_cwd_til_dir "content/til"
  add_md_files "${TEST_CWD}/content/til" "a.md" "b.md"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"Stock: 2 entries"* ]]
}

# --- 3. CWD に src/content/til/ がある → Stock 表示 ---
@test "CWD に src/content/til/ がある → 正しいカウント" {
  create_cwd_til_dir "src/content/til"
  add_md_files "${TEST_CWD}/src/content/til" "x.md" "y.md" "z.md"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"Stock: 3 entries"* ]]
  [[ "$ctx" == *"${TEST_CWD}/src/content/til"* ]]
}

# --- 4. TIL ディレクトリが空 → Stock: 0 ---
@test "TIL ディレクトリが空 → Stock: 0 entries" {
  create_cwd_til_dir "til"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"Stock: 0 entries"* ]]
}

# --- 5. 複数 .md ファイル → 正しいカウント ---
@test "複数 .md ファイル → 正しいカウント" {
  create_cwd_til_dir "til"
  add_md_files "${TEST_CWD}/til" "a.md" "b.md" "c.md" "d.md" "e.md"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"Stock: 5 entries"* ]]
}

# --- 6. .md 以外のファイル → カウント対象外 ---
@test ".md 以外のファイルはカウント対象外" {
  create_cwd_til_dir "til"
  add_md_files "${TEST_CWD}/til" "note.md" "readme.txt" "data.json" "script.sh"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"Stock: 1 entries"* ]]
}

# --- 7. config.json あり + ディレクトリ存在 → Stock 表示 ---
@test "config.json ディレクトリ存在 → Stock 表示" {
  local config_til_dir="${BATS_TEST_TMPDIR}/config-til"
  mkdir -p "$config_til_dir"
  add_md_files "$config_til_dir" "post1.md" "post2.md" "post3.md"
  create_config "$config_til_dir"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"Stock: 3 entries"* ]]
  [[ "$ctx" == *"${config_til_dir}"* ]]
}

# --- 8. config.json あり + ディレクトリ未存在 → will ask ---
@test "config.json ディレクトリ未存在 → will ask メッセージ" {
  create_config "/nonexistent/custom-til"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"will ask"* ]]
}

# --- 9. config.json なし → フォールバック表示 ---
@test "config.json なし → ~/til/ フォールバック表示" {
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"~/til/"* ]]
  [[ "$ctx" == *"configurable"* ]]
}

# --- 10. CWD ディレクトリが config より優先 ---
@test "CWD の til/ が config.json より優先される" {
  create_cwd_til_dir "til"
  add_md_files "${TEST_CWD}/til" "local.md"
  local config_til_dir="${BATS_TEST_TMPDIR}/config-til"
  mkdir -p "$config_til_dir"
  add_md_files "$config_til_dir" "a.md" "b.md" "c.md"
  create_config "$config_til_dir"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  # CWD の til/ のカウント(1)が使われる
  [[ "$ctx" == *"Stock: 1 entries"* ]]
  [[ "$ctx" == *"${TEST_CWD}/til"* ]]
}

# --- 11. JSON 出力構造が正しい ---
@test "JSON 出力に hookEventName=SessionStart が含まれる" {
  create_cwd_til_dir "til"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"'
}

# --- 12. additionalContext に "TIL auto-capture: ON" ---
@test "additionalContext に TIL auto-capture: ON が含まれる" {
  create_cwd_til_dir "til"
  local input
  input=$(generate_session_start_input "$TEST_CWD")

  run bash -c "echo '$input' | bash '$HOOK_SCRIPT'"
  [ "$status" -eq 0 ]
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  [[ "$ctx" == *"TIL auto-capture: ON"* ]]
}
