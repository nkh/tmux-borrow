# t/lib/harness.sh — private tmux server management and shared test helpers.
# Tests run against `tmux -L $TUM_TEST_SOCKET -f /dev/null`, NEVER the user's
# default server. Sourced by each step script (after assert.sh).

TUM_TEST_SOCKET="${TUM_TEST_SOCKET:-tum-test}"
TUM_BIN="${TUM_BIN:-tmux}"

# tum_t <tmux args...> — every tmux call in tests goes through this.
tum_t() { "$TUM_BIN" -L "$TUM_TEST_SOCKET" -f /dev/null "$@"; }

tum_server_start() {
  tum_t new-session -d -s __init 2>/dev/null || true
  # wait until the server actually responds (the first command on a fresh
  # socket can return non-zero for a moment while the server forks)
  local i
  for i in $(seq 1 20); do
    tum_t list-sessions >/dev/null 2>&1 && return 0
    sleep 0.1
  done
  return 0
}
tum_server_kill() {
  "$TUM_BIN" -L "$TUM_TEST_SOCKET" kill-server 2>/dev/null || true
}

# Create a fresh host window and echo its single pane id.
tum_new_host_pane() { tum_t new-window -P -n host; }

# Read a pane's title — the chosen state store (Alternative A, per the
# viability test: htop/vim/less/tail/bash all preserve a set title).
# tum-state wraps this; tests may use it directly.
tum_title_of() { tum_t display-message -p -t "$1" '#{pane_title}'; }

# Echo the current (focused) pane id on the test server.
tum_focused_pane() { tum_t display-message -p '#{pane_id}'; }

# List pane ids across all sessions, one per line.
tum_all_panes() { tum_t list-panes -a -F '#{pane_id}'; }
