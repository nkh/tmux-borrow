# Testing strategy

## Layers

1. Shell unit tests: parsing, precedence, IDs, state transitions.
2. SQLite tests: constraints, transactions, migrations, concurrent writers.
3. tmux integration tests using an isolated server socket, e.g. `tmux -L tum-test -f /dev/null`.
4. Pseudo-terminal tests for readline and popup behavior.
5. fzf tests using a deterministic fake executable.
6. End-to-end tests: start, borrow, return, stop, restore, clone.
7. Documentation checks: links, command examples, and line/table width.

## Invariants

- One managed instance has at most one live pane.
- A pane is not managed without a matching record and marker.
- An instance has at most one active borrow.
- A per-window instance has one stable working-window association.
- Borrow does not change utility PID.
- Return restores home and temporary appearance.
- Layouts never claim ordinary panes.
- Cancelled prompts cause no state change.
- Failed operations never kill unrecognized panes.
- Secrets never appear in logs, layouts, or operation payloads.

Tests must create ordinary panes as adversarial fixtures and verify their IDs, commands, and locations remain unchanged. Never use the user's default tmux server. Check every Markdown table row is at most 150 characters; report file and line number.
