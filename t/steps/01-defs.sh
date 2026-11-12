#!/usr/bin/env bash
# t/steps/01-defs.sh — Step 01: bin/tum skeleton (dispatcher + help) + tum_defs_*
# definition parser. No tmux needed (pure parsing + help + `make man`).
# Run:  make test-01-defs
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$HERE/lib/assert.sh"
# shellcheck disable=SC1091
source "$HERE/lib/harness.sh"
# shellcheck disable=SC1091
source "$HERE/../bin/tum"          # single file: dispatcher + cmd_* + helpers

plan "01 — skeleton (dispatcher + help) + tum-defs parser"

# --- parse examples/full-demo.util ------------------------------------------
FIXTURE="$HERE/../examples/full-demo.util"
parsed="$(tum_defs_parse "$FIXTURE")"

assert_eq "tail"                       "$(tum_defs_get command         <<<"$parsed")" "command"
assert_eq "l"                          "$(tum_defs_get slot            <<<"$parsed")" "slot"
assert_eq "yes"                        "$(tum_defs_get use-process-env <<<"$parsed")" "use-process-env"
assert_eq "-n 500 -f {{logfile}}"      "$(tum_defs_get args            <<<"$parsed")" "args"
assert_eq "~/projects/acme/var/log"    "$(tum_defs_get cwd             <<<"$parsed")" "cwd"
assert_contains "$parsed" "logfile" "input placeholder declared"
assert_contains "$parsed" "PAGER"   "env key PAGER present"
assert_contains "$parsed" "LESS"    "env key LESS present"
assert_contains "$parsed" "LOG_DIR" "env key LOG_DIR present"
# the six special keys are NOT env keys; env keys are everything else
assert_eq "6" "$(tum_defs_count_special <<<"$parsed")" "six special keys"
assert_eq "3" "$(tum_defs_count_env     <<<"$parsed")" "three env keys"
# the ordered accessors
assert_eq "PAGER"   "$(tum_defs_env_keys <<<"$parsed" | head -1)" "env_keys lists PAGER first"
assert_eq "logfile" "$(tum_defs_inputs   <<<"$parsed")"           "inputs lists logfile"

# --- the comment rule --------------------------------------------------------
# A `#` starts a comment only at line start or when preceded by whitespace, so a
# `#` inside a value (a URL fragment, `page#frag`) is kept; an inline `# note`
# is stripped; a full-line comment is dropped.
tmp="$(mktemp)"
{
  printf '# leading full-line comment\n'
  printf 'command: curl\n'
  printf 'args: -s http://example.com/page#frag\n'
  printf 'input: url\n'
  printf 'URL: http://h/x#y   # the base URL\n'
  printf 'PAGER: less # inline note\n'
} >"$tmp"
p2="$(tum_defs_parse "$tmp")"
assert_eq "curl"                          "$(tum_defs_get command <<<"$p2")" "comment-fixture command"
assert_eq "-s http://example.com/page#frag" "$(tum_defs_get args <<<"$p2")" "# in value kept (no space before #)"
assert_eq "http://h/x#y"                  "$(tum_defs_get URL     <<<"$p2")" "URL fragment kept, inline comment stripped"
assert_eq "less"                          "$(tum_defs_get PAGER   <<<"$p2")" "inline comment stripped"
assert_eq "3" "$(tum_defs_count_special <<<"$p2")" "comment-fixture: 3 special keys"
assert_eq "2" "$(tum_defs_count_env     <<<"$p2")" "comment-fixture: 2 env keys"
assert_contains "$(tum_defs_env_keys <<<"$p2")" "URL"   "env_keys lists URL"
assert_contains "$(tum_defs_env_keys <<<"$p2")" "PAGER" "env_keys lists PAGER"
rm -f "$tmp"

# --- dispatcher + help framework --------------------------------------------
out="$(tum --help 2>&1)"; rc=$?
assert_eq 0 "$rc" "tum --help exits 0"
assert_contains "$out" "borrow"     "tum --help lists borrow"
assert_contains "$out" "flip"       "tum --help lists flip"
assert_contains "$out" "close"      "tum --help lists close"
assert_contains "$out" "import"     "tum --help lists import"
assert_contains "$out" "cheatsheet" "tum --help lists cheatsheet"

out="$(tum 2>&1)"; rc=$?
assert_eq 0 "$rc" "bare tum exits 0"
assert_contains "$out" "borrow" "bare tum lists commands"

out="$(tum borrow --help 2>&1)"
assert_contains "$out" "SYNOPSIS"  "tum borrow --help prints SYNOPSIS"
assert_contains "$out" "EXAMPLES"  "tum borrow --help prints EXAMPLES"
assert_contains "$out" "borrow"    "tum borrow --help mentions borrow"

# every command accepts --help (even though cmd_* bodies come in later phases)
for c in new flip close push pop import ls check status popup cheatsheet; do
  assert_contains "$(tum "$c" --help 2>&1)" "SYNOPSIS" "tum $c --help prints SYNOPSIS"
done

# an unknown command errors non-zero
tum no-such-cmd >/dev/null 2>&1; assert_eq 2 "$?" "unknown command exits 2"

# --- manpages render from markdown ------------------------------------------
make -C "$HERE/.." man >/dev/null 2>&1
test -f "$HERE/../man/tum.1"      && ok "man/tum.1 rendered"      || fail "man/tum.1 missing"
test -f "$HERE/../man/tum-defs.5" && ok "man/tum-defs.5 rendered" || fail "man/tum-defs.5 missing"
