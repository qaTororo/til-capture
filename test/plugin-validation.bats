#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
}

# --- 1. plugin.json が有効な JSON ---
@test "plugin.json が有効な JSON である" {
  run jq '.' "${PROJECT_ROOT}/.claude-plugin/plugin.json"
  [ "$status" -eq 0 ]
}

# --- 2. plugin.json の必須フィールド ---
@test "plugin.json に name, version, description が存在する" {
  run jq -e '.name' "${PROJECT_ROOT}/.claude-plugin/plugin.json"
  [ "$status" -eq 0 ]

  run jq -e '.version' "${PROJECT_ROOT}/.claude-plugin/plugin.json"
  [ "$status" -eq 0 ]

  run jq -e '.description' "${PROJECT_ROOT}/.claude-plugin/plugin.json"
  [ "$status" -eq 0 ]
}

# --- 3. hooks.json が有効な JSON ---
@test "hooks.json が有効な JSON である" {
  run jq '.' "${PROJECT_ROOT}/hooks/hooks.json"
  [ "$status" -eq 0 ]
}

# --- 4. hooks.json に Stop フック定義 ---
@test "hooks.json に Stop フック定義が存在する" {
  run jq -e '.hooks.Stop' "${PROJECT_ROOT}/hooks/hooks.json"
  [ "$status" -eq 0 ]
}

# --- 5. hooks.json に SessionStart フック定義 ---
@test "hooks.json に SessionStart フック定義が存在する" {
  run jq -e '.hooks.SessionStart' "${PROJECT_ROOT}/hooks/hooks.json"
  [ "$status" -eq 0 ]
}
