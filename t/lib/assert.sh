# t/lib/assert.sh — minimal assertion helpers for tmux-borrow tests.
# Sourced by each step script. Prints PASS/FAIL lines; exits non-zero if any
# assertion failed (via the EXIT trap).
ASSERTS_PASSED=0
ASSERTS_FAILED=0

plan() { printf '\n== %s ==\n' "$1"; }
ok()   { printf 'PASS  %s\n' "$1"; ASSERTS_PASSED=$((ASSERTS_PASSED+1)); }
fail() { printf 'FAIL  %s\n' "$1" >&2; ASSERTS_FAILED=$((ASSERTS_FAILED+1)); }

assert_eq() {            # assert_eq <expected> <got> [msg]
  local exp="$1" got="$2" msg="${3:-}"
  if [[ "$exp" == "$got" ]]; then ok "${msg:+$msg: }==$exp"
  else fail "${msg:+$msg: }expected [$exp] got [$got]"; fi
}
assert_contains() {      # assert_contains <haystack> <needle> [msg]
  local hay="$1" needle="$2" msg="${3:-contains $needle}"
  if [[ "$hay" == *"$needle"* ]]; then ok "$msg"
  else fail "$msg: [$needle] not found"; fi
}
assert_not_contains() {  # assert_not_contains <haystack> <needle> [msg]
  local hay="$1" needle="$2" msg="${3:-absent $needle}"
  if [[ "$hay" != *"$needle"* ]]; then ok "$msg"
  else fail "$msg: [$needle] unexpectedly present"; fi
}
assert_match() {         # assert_match <string> <regex> [msg]
  local str="$1" re="$2" msg="${3:-matches $re}"
  if [[ "$str" =~ $re ]]; then ok "$msg"
  else fail "$msg: [$str] !~ $re"; fi
}
assert_status() {        # assert_status <expected_rc> <cmd...> — NO message arg
                          # (cmd has variable arity; for a labeled check, capture rc
                          #  yourself and use assert_eq: `cmd; rc=$?; assert_eq 0 $rc "msg"`)
  local exp="$1"; shift
  "$@" >/dev/null 2>&1; local rc=$?
  if [[ "$rc" -eq "$exp" ]]; then ok "exit $rc: $*"
  else fail "expected exit $exp got $rc: $*"; fi
}
assert_pane_title() {    # assert_pane_title <pane_id> <expected_prefix>  (uses harness tum_t)
  local pane="$1" prefix="$2"
  local title
  title="$(tum_t display-message -p -t "$pane" '#{pane_title}')"
  assert_contains "$title" "$prefix" "pane $pane title"
}

_atexit() {
  printf '\n-- %d passed, %d failed --\n' "$ASSERTS_PASSED" "$ASSERTS_FAILED"
  [[ "$ASSERTS_FAILED" -eq 0 ]]
}
trap _atexit EXIT
