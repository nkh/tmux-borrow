#!/usr/bin/env bash
# t/steps/03-tmux.sh — Step 03: the _tm wrapper and its helpers.
# Against the test server: new-window/split-window return stable pane ids;
# join-pane moves a pane into another window; move-pane relocates to a hidden
# session; select-pane -T round-trips a string via display-message (the state
# store); kill-pane removes it; list-panes -a reflects each change.
# Run:  make test-03-tmux
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$HERE/lib/assert.sh"
# shellcheck disable=SC1091
source "$HERE/lib/harness.sh"
# shellcheck disable=SC1091
source "$HERE/../bin/tum"

export TUM_SOCKET="$TUM_TEST_SOCKET"
tum_server_start

plan "03 — _tm wrapper + helpers"

# _tm honors TUM_SOCKET: a list call reaches the private test server
assert_contains "$(_tm list-sessions 2>&1)" "__init" "_tm reaches the test server"

S="s03$$"; H="hid$$"
_tm new-session -d -s "$S" -x 120 -y 40
_tm new-session -d -s "$H" 2>/dev/null || true

# new-window returns a stable pane id (%N)
p1="$(_tm new-window -P -F '#{pane_id}' -t "$S" -n w1)"
assert_match "$p1" '^%[0-9]+$' "new-window returns a pane id"

# split-window a second pane in the same window
p2="$(_tm_split "$p1" h)"
assert_match "$p2" '^%[0-9]+$' "_tm_split returns a pane id"
w1="$(_tm display-message -p -t "$p1" '#{window_id}')"
w2="$(_tm display-message -p -t "$p2" '#{window_id}')"
assert_eq "$w1" "$w2" "split panes share a window"

# join-pane moves a pane into another window (beside a target pane there)
p3="$(_tm new-window -P -F '#{pane_id}' -t "$S" -n w2)"
w_p3="$(_tm display-message -p -t "$p3" '#{window_id}')"
_tm_join "$p2" "$p3"
w_p2_after="$(_tm display-message -p -t "$p2" '#{window_id}')"
assert_eq "$w_p3" "$w_p2_after" "join-pane moved p2 into p3's window"

# move-pane relocates a pane to a hidden session (the hide mechanism)
_tm_move "$p3" "$H:"
assert_eq "$H" "$(_tm display-message -p -t "$p3" '#{session_name}')" "move-pane relocated p3 to the hidden session"

# select-pane -T round-trips a string via display-message (the state-store primitive)
_tm select-pane -t "$p1" -T 'tum:probe=round-trip;geom=80x24'
assert_eq 'tum:probe=round-trip;geom=80x24' \
  "$(_tm display-message -p -t "$p1" '#{pane_title}')" \
  "select-pane -T round-trips via display-message"

# kill-pane removes it; list-panes -a reflects the change
assert_contains  "$(_tm_list '#{pane_id}')" "$p1" "p1 present before kill"
_tm_kill "$p1"
assert_not_contains "$(_tm_list '#{pane_id}')" "$p1" "p1 gone after kill"

# _tm_list default format is the pane id
assert_match "$(_tm_list | head -1)" '^%[0-9]+$' "_tm_list default format is pane_id"

# cleanup
_tm kill-session -t "$S" 2>/dev/null || true
_tm kill-session -t "$H" 2>/dev/null || true
