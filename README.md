# tmux-borrow

A small orchestration layer over tmux that borrows long-running utilities — file managers, log tails, REPLs, database consoles, monitors, debuggers — beside the pane you are working in, hides them out of the way, brings them back, and closes them, all without restarting the process. It groups utilities into named layouts, hands a utility off to another session with push/pop, and adopts any existing pane as a temporary utility with import.

tmux-borrow is a superset of tmuxake's side-pane model: the same hide/show/close flow, generalized to named utilities, layouts, multiple instances, import, and a pluggable chooser.

## Core model

- **State lives in tmux itself.** Every borrowed pane carries its state as pane-scope `@tum-*` user options (`tmux set-option -p`). There is no external database, no index file, no metadata directory. The hidden session's pane list (queried via `tmux list-panes -a`) is the complete state.
- **A utility is always one pane.** A layout is a group of utilities; borrowing a layout borrows all its members into the host window. Borrowing moves a pane with `join-pane`/`move-pane` — the process is moved, not restarted.
- **Hide parks, close kills.** Hide (`move-pane` to the hidden session) is non-destructive and reversible; close (`kill-pane`) destroys the pane and all its state. There is no exit-policy hook: when you close a pane, it is gone and tmux-borrow does nothing further with it.
- **A single hidden session** (`@tum-hidden-session`, default `tum-hidden`) parks hidden and pushed panes. Any session can borrow from it.
- **Multiple utilities and multiple layouts may attach to one host simultaneously**, and multiple instances of one utility are allowed.
- **The manager owns only what it can prove it owns:** a `@tum-*` pane-scope option and a verified live pane id. Orphans — a half-dead binding where the host pane is gone but the utility pane is alive — are detected lazily, marked `!`, and left in place for the user to re-borrow or close.
- **Never overwrite, save, restore, or destroy ordinary working panes** when borrowing or hiding.

## Implementation

- Small, composable Unix-style programs with narrow responsibilities and clear input/output contracts. No monolith.
- Bash-first; short Perl helpers where they materially simplify parsing. No Python in runtime code.
- All tmux interaction goes through one `tum-tmux` module; all state read/write goes through one `tum-state` module.
- The chooser is an external script (`tum-chooser`, fzf is the reference implementation). The core works with no chooser installed — commands that need one fall back to erroring or a numbered list.
- tmux remains responsible for panes, windows, sessions, splitting, sizing, focus, and terminal presentation.

## Requirements

- **tmux ≥ 3.2.** Pane-scope user options (the state store) require tmux 3.0; `display-popup` (the chooser/prompt overlay) requires tmux 3.2. The binding constraint is 3.2.
- Bash 4+ (associative arrays). Linux for named import's `/proc/$pid/` capture; anonymous import and all other commands work anywhere tmux does.

## Documents

The specification lives in `docs/` as flat Markdown files:

| File                             | Contents                                                                                                                             |
| ---                              | ---                                                                                                                                  |
@| `docs/tmux-borrow-requirements.md` | The spec: core model, state representation, definitions, borrowing, flip-flop, hide/close, push/pop, import, layouts, chooser, status glyphs, listings, orphan handling, command summary, implementation constraints. |
| `docs/tmux-borrow-keymap.md`     | The key-binding layer: every `tum` command reachable from the keyboard, generated from `@tum-*` options.                             |
| `docs/user-guide.md`             | The end-user walkthrough: define a utility, borrow, hide/show, close, layouts, push/pop, import, chooser, glyphs, listings.          |
| `docs/use-cases.md`              | Fifteen functional scenarios that test whether the requirements hold together, each mapped to the requirement sections it exercises. |
| `docs/command-surface-audit.md`  | An audit of every command, flag, option, and definition key, with proposals to shrink the surface.                                   |
| `docs/component-analysis.md`     | Which existing open-source projects (fzf, gum, bats, etc.) can be reused for each component.                                         |
| `docs/tmuxake-reuse-analysis.md` | Which tmuxake ideas were adopted, extended, or skipped — and why.                                                                    |
| `docs/plugin-analysis.md`        | Architectural comparison with related tmux plugins.                                                                                  |

## Status

Design and specification stage. The requirements document is the source of truth; the keymap, user guide, and use cases mirror it. No runtime code is shipped yet.
