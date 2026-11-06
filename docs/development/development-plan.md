# Development plan

Build and test in small increments. first prove safe tracking and movement of one pane.

## Phase 0 — freeze decisions

Choose minimum tmux/SQLite versions, TOML parser, license, config schema, command names, ID format, packaging, and supported Linux targets. Exit: no undefined implementation decisions.

## Phase 1 — skeleton

Create repo structure, CLI dispatcher/help, dependency checks, config discovery, `$EDITOR` support, completion skeleton. Test help/status and ensure no tmux mutation.

## Phase 2 — config and argv

Implement TOML validation, precedence, argv arrays, required prompts, presets, and ad-hoc `--` parsing. Test spaces/special characters, non-interactive missing values, and secret redaction. No `eval`.

## Phase 3 — metadata

Implement SQLite schema/migrations, UUIDs, transactions, operation journal, and listing. Test constraints, concurrency, interrupted transactions, and migrations.

## Phase 4 — tmux adapter and single utility

Create home session/window, launch one utility, record IDs/PID, verify ownership, and stop. Test with isolated tmux server; failed launch must clean up only created resources.

## Phase 5 — borrow/return

Implement pane borrow, host association, home placeholder, return, appearance snapshot/restore. Test PID preservation, location verification, host closure, rollback, and external movement detection.

## Phase 6 — instances and selection

Implement shared/per-window policies, unique auto-selection, `--instance`, fzf, batch preflight. Test multiple instances, two working windows, one-borrow-at-a-time, and cancellation.

## Phase 7 — layouts

Implement save-managed-only, incremental restore, argument persistence choice, and separate-window mode. Test ordinary panes unchanged, prompts collected first, and conflict behavior.

## Phase 8 — clone

Implement shared reuse, per-window instance creation, new-instance rules, destination prompts, and source immutability. Test no source pane moves and no secret copying.

## Phase 9 — UI

Implement popup, fzf, readline fallback, config/layout wizard, and tree view only if justified. Test popup delegates to CLI and cancellation is side-effect free.

## Phase 10 — lifecycle and release

Add opt-in hooks, reconciliation, completion, diagnostics, repair, man page, packaging. Test hook failures, keep-running default, clean install/uninstall, archive integrity, docs checks.

## Definition of done

All P0 requirements pass; integration tests run on supported tmux versions; help matches docs; no ordinary pane is moved, killed, or resized by utility-only operations.
