# tmuxake — reuse analysis for tmux-borrow

tmux-borrow is a superset of tmuxake. This document records which tmuxake ideas were adopted, which were extended, and which were skipped — and why. We take ideas only; no code is lifted from tmuxake. Everything will be reimplemented in tmux-borrow's own codebase.

tmuxake is a single ~1340-line bash script by Nadim Khemir. It manages "side-panes" — a scratch shell bound to a host pane, stashed in a hidden session when not in use, toggled in and out with one key, closed with another. tmux-borrow takes that core flow and generalizes it to named utilities, layouts, multiple instances, import, push/pop, and a pluggable chooser.

---

## How tmuxake works

A side-pane is an ordinary tmux pane running a shell, bound one-to-one to a "root-pane" (the host). The binding lives in tmux itself: when a side-pane is hidden, it is `move-pane`'d into a window in a hidden session named `tmuxake`, and that window's *name* encodes the whole relationship — `<root_pid>-<side_pid>@<position><size>@<date>`. The window list of the `tmuxake` session is the entire state. There is no database, no config file, no marker on the pane.

Pane identity is by `pane_pid` (the shell's PID), which survives `move-pane` and `join-pane`. Position and size are remembered in the encoded name and restored on show.

The commands that matter:

- **toggle** — if the current pane has no side-pane, create one. If visible, hide it. If hidden, show it. One key, three outcomes.
- **close** — destroy the side-pane. Works from either pane: it checks whether the current pane is a root with a side, or is itself a side, and resolves the partner either way.
- **hide / show** — the two halves of toggle. Hide is `move-pane` into the `tmuxake` session; show is `join-pane` back, restoring recorded geometry.
- **detach / attach** — break the binding, name the side-pane, re-attach it later to a different root.
- **import** — turn an ordinary tmux pane into a detached side-pane.
- **push / pop** — a one-slot stack: push detaches as `pushpop0`, pop attaches it in any session.
- **check / status / status2** — list side-panes, detect dead PIDs (orphans), emit glyphs for the prompt and status bar.

---

## Ideas adopted

These tmuxake ideas are in tmux-borrow's requirements, reimplemented in tmux-borrow's own way.

| Idea                       | How tmux-borrow uses it                                                                                                                    |
| ---                        | ---                                                                                                                                        |
| State in tmux, no database | All state as pane-scope `@tum-*` options on each utility pane. No sqlite, no index. The hidden session pane list is the complete state.    |
| One shared hidden session  | A single configurable session parks hidden and pushed panes. Any session can borrow from it.                                               |
| Toggle (create/show/hide)  | Borrow does this: hidden instance bound to this host, else existing hidden, else create. Flip-flop toggles by slot key.                    |
| Close from side or host    | Close is context-aware: from a borrowed pane closes it; from host with one borrowed closes it; with several, chooser picks.                |
| Close is just `kill-pane`  | No teardown, no cleanup. State dies with the pane.                                                                                         |
| Geometry memory            | Width and height are captured at hide (`@tum-geometry`) and restored on show.                                                              |
| Status glyphs              | `÷` for a host with borrowed things, `§` for a borrowed pane, `!` for an orphan. Configurable, tmuxake-like defaults.                      |
| Orphan detection           | No proactive hooks. Dead host leaves utility marked `!` until re-borrow or close. `check` lists orphans. Full-dead panes auto-removed. |
| Import                     | Adopt an existing pane as a utility. tmux-borrow adds a named variant that captures command/args/cwd/env to a definition file.             |
| Push / pop                 | LIFO stack for cross-session hand-off. Extended to multi-slot (non-contiguous seqs, since panes may be closed between pushes).             |

---

## Ideas extended

tmux-borrow takes these tmuxake concepts and generalizes them.

| tmuxake concept               | tmux-borrow extension                                                                                                           |
| ---                           | ---                                                                                                                             |
| One side-pane per root pane   | Multiple utilities and multiple layouts may attach to one host simultaneously.                                                  |
| A side-pane is always a shell | A utility is any named command with a definition file (command, args, cwd, env, slot).                                    |
| No grouping                   | Layouts group utilities; borrowing a layout borrows all members; members anchor to the host or to each other.                   |
| One instance per root         | Multiple instances of one utility are allowed. `borrow` reuses an existing hidden instance (else creates); `new` always creates.         |
| Window name encodes state     | tmux-borrow uses pane-scope `@tum-*` options instead — more robust than parsing a string, and they survive `move-pane` cleanly. |
| PID-based identity            | Pane id (`%N`) for binding — stable, never reused, no `kill -0`. PID read ephemerally at import only.                           |
| Single toggle key             | Slot keys: every borrowed thing (utility, layout, or layout member) gets a slot for individual or group flip-flop.              |
| `detach`/`attach` by name     | Borrow by name, by tag, or with no name (chooser over all). Resolution: host-bound first, else existing, else create.           |
| `push`/`pop` one slot         | LIFO stack of multiple panes; pop attaches at recorded geometry.                                                                |

---

## Ideas skipped

| Idea                         | Why skipped                                                                                                                                         |
| ---                          | ---                                                                                                                                                 |
| Window-name-as-state         | Pane-scope `@tum-*` options are more robust (no string parsing, survive moves cleanly) and carry richer fields (layout id, source, geometry). |
| PID as the binding key       | PIDs recycle; pane ids are monotonic and never reused. Pane id is strictly better for binding and orphan detection.                                 |
| `kill -0` orphan detection   | With pane id, the check is "stored pane id in `list-panes -a`?" — no process probing, no PID-recycling risk.                                        |
| Env via show-env + send-keys | Fragile (tmuxake spells out keys to dodge quoting). tmux-borrow sets env at launch via `tum-tmux`.                                                  |
| Encoded name as state        | Keeps the principle (state in tmux) but uses pane options — structured and queryable, not a parsed string.                                          |

---

## Architecture lessons

tmuxake's architecture is the opposite of a database-backed manager, and the contrast is the lesson tmux-borrow takes to heart.

- **State in tmux, not beside it.** The hidden session's pane list is the database. Nothing to corrupt, nothing to reconcile after a crash, nothing to clean up on death. tmux-borrow adopts this fully — pane-scope options die with the pane, so full-dead cleanup is automatic.
- **Function-per-command.** tmuxake's script doubles as a library and a CLI. tmux-borrow follows the same shape: small utilities with narrow responsibilities, clear input/output contracts, no monolith.
- **Pane introspection via formats.** Heavy use of `#{pane_pid}`, `#{pane_id}`, `#{pane_current_path}`, `#{pane_width}`, `#{pane_height}`. These are the right tmux-native primitives; tmux-borrow uses the same ones through its `tum-tmux` adapter.
- **Zero deps.** tmuxake needs only tmux and bash. tmux-borrow keeps the core dependency-free; the chooser is an external script (fzf is one implementation, not a dependency of the core).

---

## What tmux-borrow adds beyond tmuxake

These are tmux-borrow's own contributions, not from tmuxake:

- **Named utilities and layouts** as flat `key:value` files, filename as name, no collisions.
- **Layouts** as groups of utilities with a member-anchoring DSL.
- **Multiple instances** with `tum borrow` (reuse-or-create) and `tum new` (always-create), host-bound-first resolution.
- **A chooser API** (`tum-chooser <prompt> <items_file> <output_file>`) that decouples the selection UI from the core — any script following the contract is a drop-in. The chooser is implicit: commands invoke it internally when a choice is needed, so there is no `--interactive` flag.
- **Slot keys** for individual and group flip-flop across multiple attached things.
- **Named import** that captures process fidelity to an editable definition file.
- **`tum ls`** as a global view of all instances across all sessions.

tmux-borrow is tmuxake's hide/show/close flow, made general. The requirements document carries the full specification.
