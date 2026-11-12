#!/usr/bin/env bash
# t/viability.sh — R1 state-store viability test.
# Decides Alternative A (pane title) vs Alternative B (pane-scope @tum-state).
#
# The real tum flow is: split-window launches the utility, then tum writes its
# state to the pane title. A utility that emits continuous xterm title escapes
# (\e]2;...\e\\) overwrites tum's title and silently loses state. So the probe
# matches that flow: launch the utility, let it settle, set the title, wait
# through a refresh, and check whether the title survived.
#
# Verdict: a SINGLE common target clobbering the title is enough to reject A,
# because the failure mode is silent state loss for that utility (not "most
# utilities are fine"). Only if NONE clobber is A viable.
#
# Run:   make viability
set -uo pipefail
SOCKET="${TUM_TEST_SOCKET:-tum-test}"
TMUX="tmux -L $SOCKET -f /dev/null"

if ! command -v tmux >/dev/null 2>&1; then
  echo "viability: tmux is not installed — install tmux (and the target utilities) and re-run." >&2
  exit 2
fi

# name|launch-command — the launch command keeps the utility alive long enough
# to probe (a bare `less` or `tail` exits immediately on a detached pane).
UTILS=(
  "htop|htop"
  "vim|vim -u NONE /etc/hostname"
  "less|less /etc/hostname"
  "man|man man"
  "lazygit|lazygit"
  "tail|tail -f /etc/hostname"
  "bash|bash"
  "ranger|ranger"
  "psql|psql"
)

printf '== viability test: does each utility overwrite the pane title? ==\n'
$TMUX kill-server 2>/dev/null || true
$TMUX new-session -d -s probe

pass=0; fail=0; skip=0; failed_list=()
for entry in "${UTILS[@]}"; do
  u="${entry%%|*}"; cmd="${entry#*|}"
  if ! command -v "$u" >/dev/null 2>&1; then
    printf 'SKIP    %-10s (not installed)\n' "$u"; skip=$((skip+1)); continue
  fi
  pane="$($TMUX split-window -h -P -t probe -d bash -lc "$cmd" 2>/dev/null)" || {
    printf 'ERROR   %-10s (launch failed)\n' "$u"; skip=$((skip+1)); continue; }
  sleep 1                                  # let startup escapes fire + utility settle
  $TMUX select-pane -t "$pane" -T 'tum:probe=1'   # tum writes state AFTER launch
  sleep 2                                  # wait through a refresh cycle
  title="$($TMUX display-message -p -t "$pane" '#{pane_title}' 2>/dev/null)"
  if [[ "$title" == tum:* ]]; then
    printf 'PASS    %-10s (title intact)\n' "$u"; pass=$((pass+1))
  else
    printf 'FAIL    %-10s (title clobbered: %s)\n' "$u" "$title"; fail=$((fail+1)); failed_list+=("$u")
  fi
  $TMUX kill-pane -t "$pane" 2>/dev/null || true
done

printf '\nresult: %d intact, %d clobbered, %d skipped\n' "$pass" "$fail" "$skip"
if (( fail == 0 )); then
  printf '=> no target utility clobbered the title: Alternative A (pane title) is viable.\n'
else
  printf '=> %s clobbered the title.\n' "${failed_list[*]}"
  printf '=> any clobberer means silent state loss for that utility: choose Alternative B (pane-scope @tum-state).\n'
fi
$TMUX kill-server 2>/dev/null || true
