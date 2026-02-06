#!/bin/bash
# test-helper.bash: 共通セットアップ/ヘルパー関数

# プロジェクトルート
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- 共通 setup ---
common_setup() {
  # HOME を隔離
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"

  # テスト用作業ディレクトリ
  export TEST_CWD="${BATS_TEST_TMPDIR}/project"
  mkdir -p "$TEST_CWD"

  # ユニークな session_id
  export TEST_SESSION_ID="test-$$-${BATS_TEST_NUMBER}"
}

# --- 共通 teardown ---
common_teardown() {
  # テスト用状態ファイルを掃除
  rm -f "/tmp/til-capture-${TEST_SESSION_ID}"
}

# --- トランスクリプト生成 ---
# 引数: 含めたいツール名のリスト (例: "WebSearch" "WebFetch")
create_transcript() {
  local transcript_path="${BATS_TEST_TMPDIR}/transcript.jsonl"
  : > "$transcript_path"

  for tool_name in "$@"; do
    echo "{\"type\":\"tool_use\",\"name\":\"${tool_name}\",\"input\":{}}" >> "$transcript_path"
  done

  # 最低限のエントリがない場合は空でないファイルにする
  if [[ $# -eq 0 ]]; then
    echo '{"type":"text","text":"hello"}' >> "$transcript_path"
  fi

  echo "$transcript_path"
}

# --- stop-hook 用 JSON 入力生成 ---
generate_stop_hook_input() {
  local session_id="${1:-$TEST_SESSION_ID}"
  local transcript_path="${2:-${BATS_TEST_TMPDIR}/transcript.jsonl}"
  local cwd="${3:-$TEST_CWD}"
  local stop_hook_active="${4:-false}"

  jq -n \
    --arg sid "$session_id" \
    --arg tp "$transcript_path" \
    --arg cwd "$cwd" \
    --arg sha "$stop_hook_active" \
    '{
      session_id: $sid,
      transcript_path: $tp,
      cwd: $cwd,
      stop_hook_active: ($sha == "true")
    }'
}

# --- session-start-hook 用 JSON 入力生成 ---
generate_session_start_input() {
  local cwd="${1:-$TEST_CWD}"

  jq -n \
    --arg cwd "$cwd" \
    '{
      cwd: $cwd
    }'
}

# --- config.json 作成 ---
create_config() {
  local til_dir="$1"
  local config_dir="${HOME}/.config/til-capture"
  mkdir -p "$config_dir"
  jq -n --arg dir "$til_dir" '{ defaultTilDir: $dir }' > "${config_dir}/config.json"
}

# --- TIL ディレクトリ作成（CWD 配下） ---
create_cwd_til_dir() {
  local subpath="$1"
  mkdir -p "${TEST_CWD}/${subpath}"
}

# --- TIL ディレクトリに .md ファイルを追加 ---
add_md_files() {
  local dir="$1"
  shift
  for name in "$@"; do
    touch "${dir}/${name}"
  done
}
