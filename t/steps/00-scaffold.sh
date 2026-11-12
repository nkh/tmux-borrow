#!/usr/bin/env bash
# t/steps/00-scaffold.sh — Step 00: repo scaffold + test harness.
# Verifies the harness loads, the dispatcher handles a missing step as PENDING,
# and (when tmux is present) the private test server starts and stops.
# Run:  make test-00-scaffold
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$HERE/lib/assert.sh"
# shellcheck disable=SC1091
source "$HERE/lib/harness.sh"

plan "00 — scaffold + harness"

# the harness and its helpers are defined
assert_eq "$TUM_TEST_SOCKET" "${TUM_TEST_SOCKET:-tum-test}" "socket var set"
assert_match "$(declare -f tum_t)"        'tum_t'        "tum_t defined"
assert_match "$(declare -f tum_server_start)" 'tum_server_start' "server-start defined"
assert_match "$(declare -f assert_eq)"    'assert_eq'    "assert_eq defined"

# the dispatcher reports PENDING (exit 0) for a step with no script
out="$(bash "$HERE/run.sh" zz-nonexistent 2>&1)"; rc=$?
assert_status 0 true   # placeholder so assert_status is exercised
assert_contains "$out" "PENDING" "missing step reported PENDING"
assert_eq 0 "$rc" "missing step exits 0"

# if tmux is installed, the private server starts/stops on the test socket
if command -v tmux >/dev/null 2>&1; then
  tum_server_start
  tum_t has-session -t __init >/dev/null 2>&1; _rc=$?
  assert_eq 0 "$_rc" "server up + init session (has-session)"
  assert_contains  "$(tum_t list-sessions 2>&1)" "__init"  "init session present"
  tum_server_kill
else
  ok "tmux absent here — server-start/stop skipped (run on a host with tmux)"
fi
