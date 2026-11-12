#!/usr/bin/env bash
# t/run.sh — dispatch one test step against the private tmux test server.
# Usage:   t/run.sh <step-id>        e.g. t/run.sh 01-defs
#
# A step script lives at t/steps/<step-id>.sh and sources assert.sh + harness.sh
# itself. If the script does not exist yet, the step is reported PENDING and
# exits 0, so `make test` works from day one and steps go from PENDING to PASS
# as modules are implemented.
set -uo pipefail
STEP="${1:?step id required (e.g. 01-defs)}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/steps/${STEP}.sh"
export TUM_TEST_SOCKET="${TUM_TEST_SOCKET:-tum-test}"

if [[ ! -f "$SCRIPT" ]]; then
  printf 'PENDING  %-18s (create %s to implement)\n' "$STEP" "$SCRIPT"
  exit 0
fi

# Ensure a server is up for steps that need tmux. Steps that don't (pure
# parsers) simply never call tum_t. TUM_BIN defaults to tmux; harness.sh
# re-declares it for the step scripts that source it.
_tbin="${TUM_BIN:-tmux}"
"$_tbin" -L "$TUM_TEST_SOCKET" -f /dev/null info >/dev/null 2>&1 \
  || "$_tbin" -L "$TUM_TEST_SOCKET" -f /dev/null new-session -d -s __init 2>/dev/null || true

bash "$SCRIPT"
