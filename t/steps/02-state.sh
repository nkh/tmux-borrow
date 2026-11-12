#!/usr/bin/env bash
# t/steps/02-state.sh — Step 02: tum_state_* field codec (Alternative A: pane title).
# Round-trip every field; hide (host empty) reads empty; a fresh pane is
# unmanaged; a single-field update leaves the others intact.
# Run:  make test-02-state
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$HERE/lib/assert.sh"
# shellcheck disable=SC1091
source "$HERE/lib/harness.sh"
# shellcheck disable=SC1091
source "$HERE/../bin/tum"

export TUM_SOCKET="$TUM_TEST_SOCKET"      # point the runtime _tm at the test server
tum_server_start

plan "02 — tum-state codec (pane title, Alternative A)"

S="s02$$"
_tm new-session -d -s "$S" -x 100 -y 30
pane="$(_tm new-window -P -F '#{pane_id}' -t "$S" -n host)"
assert_match "$pane" '^%[0-9]+$' "new host pane id is a stable %N"

# a fresh pane is NOT managed
tum_state_has_prefix "$pane"; assert_eq 1 "$?" "fresh pane unmanaged (no tum: prefix)"
tum_state_get "$pane" util 2>/dev/null; assert_eq 1 "$?" "get on unmanaged pane fails"

# round-trip every field (all eight, in codec order)
tum_state_set "$pane" util  "simple"
tum_state_set "$pane" host  "$pane"
tum_state_set "$pane" home  ""
tum_state_set "$pane" slot  "1"
tum_state_set "$pane" geom  "80x24"
tum_state_set "$pane" src   "defined"
tum_state_set "$pane" lay   ""
tum_state_set "$pane" push  ""
tum_state_has_prefix "$pane"; assert_eq 0 "$?" "managed after first set"
assert_eq "simple"  "$(tum_state_get "$pane" util)"  "util round-trip"
assert_eq "$pane"   "$(tum_state_get "$pane" host)"  "host round-trip"
assert_eq ""        "$(tum_state_get "$pane" home)"  "home empty (pool)"
assert_eq "1"       "$(tum_state_get "$pane" slot)"  "slot round-trip"
assert_eq "80x24"   "$(tum_state_get "$pane" geom)"  "geom round-trip"
assert_eq "defined" "$(tum_state_get "$pane" src)"   "src round-trip"
assert_eq ""        "$(tum_state_get "$pane" lay)"   "lay empty"
assert_eq ""        "$(tum_state_get "$pane" push)"  "push empty"

# hide: set host empty, read empty; the rest is undisturbed
tum_state_set "$pane" host ""
assert_eq ""       "$(tum_state_get "$pane" host)" "host empty after hide"
assert_eq "simple" "$(tum_state_get "$pane" util)" "util survives hide"
assert_eq "1"      "$(tum_state_get "$pane" slot)" "slot survives hide"

# an isolated update does not disturb other fields
tum_state_set "$pane" geom "120x40"
assert_eq "120x40" "$(tum_state_get "$pane" geom)" "geom updated"
assert_eq "simple" "$(tum_state_get "$pane" util)" "util untouched by geom update"
assert_eq "1"      "$(tum_state_get "$pane" slot)" "slot untouched by geom update"
assert_eq ""       "$(tum_state_get "$pane" host)" "host untouched by geom update"

# the full encoded title is visible in the pane title (the chosen store)
title="$(_tm display-message -p -t "$pane" '#{pane_title}')"
assert_contains "$title" "tum:"         "title carries tum: prefix"
assert_contains "$title" "util=simple"  "title carries util=simple"
assert_contains "$title" "geom=120x40"  "title carries geom=120x40"
assert_contains "$title" "host=;"       "title carries empty host field"

# a second fresh pane is still unmanaged (the prefix check is per-pane)
pane2="$(_tm new-window -P -F '#{pane_id}' -t "$S" -n other)"
tum_state_has_prefix "$pane2"; assert_eq 1 "$?" "second fresh pane unmanaged"

_tm kill-session -t "$S" 2>/dev/null || true
