# tmux-borrow

A small orchestration layer over tmux that borrows long-running utilities — file managers, log tails, REPLs, database consoles, monitors, debuggers — beside the pane you are working in, hides them out of the way, brings them back, and closes them, all without restarting the process. It groups utilities into named layouts, hands a utility off to another session with push/pop, and adopts any existing pane as a temporary utility with import.

tmux-borrow is a superset of tmuxake's side-pane model: the same hide/show/close flow, generalized to named utilities, layouts, multiple instances, import, and a pluggable chooser.

## Core model

- **Dynamic state lives in the pane title.** Every borrowed pane carries its state as a structured `tum:`-prefixed string in its tmux pane title (`select-pane -T`), chosen by a viability test (no tested target utility clobbers the title). Static configuration (the chooser script, the glyphs, the hidden-session name) lives in `@tum-*` tmux options. There is no external database, no index file, no metadata directory. The hidden session's pane list (queried via `tmux list-panes -a`) is the complete state.
- **A utility is always one pane.** A layout is a group of utilities; borrowing a layout borrows all its members into the host window. Borrowing moves a pane with `join-pane`/`move-pane` — the process is moved, not restarted.
- **Hide parks, close kills.** Hide (`move-pane` to the hidden session) is non-destructive and reversible; close (`kill-pane`) destroys the pane and all its state. There is no exit-policy hook: when you close a pane, it is gone and tmux-borrow does nothing further with it.
- **Pool and owned utilities.** `tum borrow` creates pool instances (no home host; any host can borrow them). `tum new` creates owned instances (bound to a home host; flip-flop returns them only to that host). Either accepts no name to open the chooser.
- **A single hidden session** (`@tum-hidden-session`, default `tum-hidden`) parks hidden and pushed panes. Any session can borrow from it.
- **Multiple utilities and multiple layouts may attach to one host simultaneously**, and multiple instances of one utility are allowed.
- **The manager owns only what it can prove it owns:** a recognized `tum:` state string on a verified live pane id. Orphans — a half-dead binding where the host pane is gone but the utility pane is alive — are detected lazily, marked `!`, and left in place for the user to re-borrow or close.
- **Never overwrite, save, restore, or destroy ordinary working panes** when borrowing or hiding.

> **State store — resolved (Alternative A).** Dynamic state lives in the pane title (`select-pane -T`). The viability test (`make viability`, tmux 3.5a) checked `htop`, `vim`, `less`, `tail`, and `bash`; none clobbered a set title, so the title is the chosen store. A pane-scope `@tum-state` option is the documented fallback, isolated behind one `tum-state` function group. See the requirements doc for the test and the trade-offs.

## Implementation

- **Single file, one dispatcher.** All runtime code lives in `bin/tum`: every command is a small bash function grouped with its helpers, and a `case` dispatcher routes `tum <cmd> …` to it. A function that grows past ~40 lines is a signal to factor helpers out, not to split the file. The only code outside `bin/tum` is `scripts/tum-chooser` (an external fzf wrapper invoked by contract) and the static `scripts/tum-bindings.conf`.
- Bash-first; short Perl helpers where they materially simplify parsing. No Python in runtime code.
- All tmux interaction goes through one `tum-tmux` function group; all state read/write goes through one `tum-state` function group (which encapsulates the title-vs-option store choice).
- The chooser is an external script (`tum-chooser`, fzf is the reference implementation). The core works with no chooser installed — commands that need one fall back to erroring or a numbered list.
- The key bindings ship as a single static file, `tum-bindings.conf`, that you source from `tmux.conf` and edit in place to remap.
- Every `tum <cmd>` takes `-h`/`--help`, and every command has a manpage generated from `man/*.md` by `make man`.
- tmux remains responsible for panes, windows, sessions, splitting, sizing, focus, and terminal presentation.

## Requirements

- **tmux ≥ 3.2.** The binding constraint is `display-popup`, used for the chooser and prompt overlays, which requires tmux 3.2. (The pane title has existed since tmux 1.x; state storage does not gate the version.) State the floor in user-facing docs as "tmux 3.2 or newer."
- Bash 4+ (associative arrays). Linux for named import's `/proc/$pid/` capture; anonymous import and all other commands work anywhere tmux does.

## Documents

Three documents in `docs/`, plus manpage sources in `man/`:

| File | Contents |
| --- | --- |
| `docs/tmux-borrow-requirements.md` | The spec (source of truth): core model, state representation, definitions, borrowing, flip-flop, hide/close, push/pop, import, layouts, chooser, status glyphs, listings, orphan handling, command summary, help & manpages, implementation constraints. |
| `docs/implementation-roadmap.md` | The chronological build plan: phases, steps, a test per step, Make targets, the function map. |
| `docs/design-rationale.md` | The *why*: design lineage from tmuxake, related-work survey, component-reuse choices, command-surface rationale, and validation scenarios. |
| `man/*.md` | Manpage sources (rendered by `make man`): `tum`(1), one `tum-<cmd>`(1) per subcommand, `tum-defs`(5) (the `.util`/`.layout` format), `tum-keymap`(5) (the full keymap). The user guide and keymap live here, not in `docs/`. |

The earlier design-process docs (component analysis, command-surface audit,
tmuxake reuse analysis, plugin analysis, use cases, user guide, keymap) were
folded into `design-rationale.md` and the manpages; their decisions live in
the spec, and the older files are recoverable in git history.

## Status

Design and specification stage. The requirements document is the source of truth; the roadmap is the build plan. R1 (the state-store choice) is resolved — Alternative A (pane title). Manpage sources are in place (`make man` renders them). No runtime code is shipped yet.
