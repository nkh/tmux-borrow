# tmux-borrow — requirements

## Product overview

### Problem

Power users keep file managers, log followers, REPLs, database consoles, monitors, debuggers, and build watchers running inside tmux. They want to move an already-running utility into the window where they are working and later send it back — without restarting the process and losing its state.

Users want to save and restore recurring arrangements based on their current setup, and to have a single interactive interface for managing all of them.

Users want to start utilities with a saved configuration, including required arguments, working directory, and lifecycle policy and layout. Some tmux plugins already offer this, but they do not provide a unified interface for managing multiple utilities.

****### Goal

A small orchestration layer over tmux to:

- Register definitions and launch registered or ad-hoc utilities.
- Support multiple instances of one definition.
- Keep instances in managed home sessions/windows when not borrowed.
- Borrow one pane into the current window or move a whole managed window.
- Associate a borrowed pane with a host pane for manager-mediated moves.
- Borrow several utilities or arrange them in separate windows.
- Save/restore/clone layouts containing only managed utility panes.
- Prompt for missing arguments and support named argument presets.
- Keep the implementation small and split into independent commands.

### Non-goals

- Reimplement tmux navigation, zoom, resizing, splitting, or session management.
- Display one tmux pane in multiple windows simultaneously (a pane exists in one window at a time).
- General-purpose process checkpointing, migration, or suspension.
- Manage ordinary user panes as utility resources.

---

## Glossary

| Term                | Meaning                                                                                                                               |
| ---                 | ---                                                                                                                                   |
| Utility             | A long-running command managed as a movable tmux resource (`htop`, `lazygit`, a log tail, REPL, file manager, debugger).              |
| Definition          | Saved configuration describing how to start a utility (command, args, scope, home, lifecycle).                                        |
| Instance            | One running occurrence of a utility. One definition may have many instances.                                                          |
| Home session/window | The managed location where an instance lives when not borrowed. A utility occupies a full window in its home session.                 |
| Working window      | The tmux window where the user is doing other work, into which utilities are borrowed.                                                |
| Borrow              | Move an existing running pane or window into a working context. The process is moved, not restarted.                                  |
| Return              | Move a borrowed resource back to its recorded home.                                                                                   |
| Host pane           | The pane beside which a utility is borrowed. A manager-recorded association, not a tmux parent/child link.                            |
| Scope               | Whether an instance is `shared` (reusable across windows, one borrow at a time) or `per_window` (tied to one working window).         |
| Layout              | A named recipe containing only manager-owned borrowed panes and their arrangement. Ordinary panes are never part of a layout.         |
| Ordinary pane       | A pane not owned or tracked by the manager. The manager must never move, kill, or serialize it.                                       |
| Selector            | The interactive popup interface (fzf-based, with a numbered fallback) for choosing utilities, instances, panes, layouts, and actions. |
| Workspace           | The project context, derived from the shell's current directory, used to auto-associate per-window instances and suggest layouts.     |
| Label               | A free-form tag on an instance, independent of its definition, marking why this particular copy exists.                               |
| Category            | A tag on a definition or layout (`monitor`, `files`, `db`, `repl`) used to group or filter listings.                                  |
| Stale record        | An instance record whose recorded pane or PID no longer matches live tmux.                                                            |
| Environment profile | A named, switchable set of environment variables applied at launch on top of a definition's per-utility environment.                  |

---

## Core model

These are the fundamental invariants the rest of the requirements build on.

- A definition may accept positional arguments and named options; one definition may create many instances.
- Each instance is assigned a home session (manually or by policy) and occupies a full tmux window there.
- Borrowing moves a pane or window without restarting its process. A pane exists in one window at a time.
- Any eligible pane in any session can be borrowed — not just managed instances. Manager-owned panes retain identity and return metadata; ordinary panes can be borrowed and returned.
- Multiple borrowed utilities may coexist in one working window, including from different home sessions.
- Session names are labels, not keys. Two sessions may share a visible name; the manager distinguishes them by stable internal IDs.
- The manager owns only what it can prove it owns: a record, a marker, and a verified live pane identity.

---

***## Functional requirements

| Requirement          | What it is for                                 | How it could be met                                                          |
| ---                  | ---                                            | ---                                                                          |
| Register definitions | name and store utility configs once            | TOML `[utility.NAME]`; `tum define add --wizard`                             |
| Launch utility       | start a registered utility in its managed home | `tum run NAME` creates the home window and launches argv                     |
| Ad-hoc launch        | run a one-off command with full tracking       | `tum run --name X -- …`; gets a session and stable ID                        |
| Multiple instances   | run several copies of one definition           | each `tum run` creates a new instance with its own ID                        |
| Borrow pane          | bring a running process beside you, no restart | `tum borrow` uses `join-pane` to move the existing pane                      |
| Re:wturn pane          | send a borrowed pane back to its home          | `tum return` moves it home and restores appearance                           |
| instances       | see what runs, where, and in what state        | `tum list` shows ID, definition, state, home/current                         |
| Selection            | resolve which instance an action targets       | auto-select if unique; `--instance ID` or fzf if ambiguous                   |
| fzf selector         | search and pick instances interactively        | `--fzf` flag; multi-select only for batch-safe commands                      |
| Required arguments   | avoid launching with missing context           | prompt before move; fail non-interactively with names                        |
| Safe argv            | prevent injection and argument-boundary loss   | store as array; never `eval`; no `sh -c` unless user picks                   |
| Stop instance        | terminate a managed instance from anywhere     | `tum stop`; targets the instance, never host or ordinary pane                |
| Exit policy          | control what happens when the process exits    | `wait` (default), `shell`, `close`, or `leave`                               |
| Save layout          | capture a borrowed arrangement for reuse       | `tum layout save` records only manager-owned panes                           |
| Restore layout       | rebuild without harming ordinary panes         | incremental add; never wholesale `select-layout` mixed                       |
| Config editor        | edit config without knowing its path           | `tum config edit` opens it in `$EDITOR`                                      |
| Layout editor        | edit a named layout without its path           | `tum layout edit NAME` opens it in `$EDITOR`                                 |
| Wizard/template      | make registration approachable                 | `--wizard` (readline Q&A) or `--template` (append block)                     |
| Clone layout         | reuse for another project, no source moves     | `tum layout clone SRC DEST`; shared reuse, per-window create                 |
| Per-window instances | tie an instance to one window                  | stable workspace record; create one if none exists                           |
| Shared instances     | reuse one instance across windows              | one borrow at a time; enforced transactionally                               |
| Window borrow        | move a complete managed window                 | `tum borrow --as window` uses `move-window`                                  |
| Host association     | link borrowed pane to its host                 | record host pane ID; reconcile on next manager op                            |
| Lifecycle hooks      | react to idle/borrow/return/stop               | optional executable+argv hooks; failures reported                            |
| Temporary appearance | mark borrowed panes visually                   | snapshot styles before borrow; restore on return                             |
| Argument presets     | save named argument sets                       | `[preset.UTILITY.NAME]` blocks; referenced by layouts                        |
| Bash completion      | complete commands and names                    | `tum-completion` helper sourced from `.bashrc`                               |
| Tree selector        | show sessions/windows/instances                | fzf tree view; optional, only if justified                                   |
| Argument save policy | control what a layout stores                   | `omit` (default), `preset`, or `values` (non-secrets)                        |
| Recovery             | reconcile after interruption                   | `tum doctor` vs live tmux; offers repair, no silent discard                  |
| Manage current pane  | adopt an existing pane as a utility            | `tum manage` builds a definition and instance from the active pane's command |
| Validate executable  | fail early on a bad command                    | `tum run` checks the path exists and is executable before launching          |
| Workspace detection  | auto-associate without naming                  | infer the current workspace from the shell's cwd                             |
| Environment profiles | switch env sets by name                        | named profiles applied on top of the per-utility env                         |

---

## Instances and listings

**Purpose.** Once several utilities are running, the user needs to find the right one fast and trust that what the list says matches reality.

A single `tum list` nests live instances under their definitions, so one view answers both "what can I run?" and "what's running?". The list can be narrowed by definition, state, session, workspace, label, or category, so common questions — all borrowed instances, everything in session `dev`, the `per_window` instances for this window — are a filter away.

Each instance shows its current and home location in human-readable `session:window` form, its uptime, and the timestamps of its most recent borrow and return. Uptime tells you whether a home instance is the long-lived one you expected or a quiet restart; the borrow and return times reveal whether a shared instance is actually used and surface reap candidates that have been idle for weeks. The list can be sorted by recent activity on request.

Free-form labels (`prod`, `scratch`, `debug-repro`) mark why a particular copy exists, independent of its definition. This answers the question definitions can't: of five `ranger` copies, which one is tied to the incident. Definitions carry categories (`monitor`, `files`, `db`, `repl`) for grouping and filtering; labels on instances are the orthogonal, per-copy marker, especially useful for ad-hoc instances that have no meaningful name.

Frequently used instances can be pinned so they sort to the top, survive a "hide inactive" filter, and are never swept by cleanup. Rarely-used definitions can be hidden from the quick-borrow picker while still launchable explicitly by name — useful for tools that exist only as layout members. From the list, starting a second copy of a definition (a second `ranger` rooted elsewhere) needs no retyping.

The list must reflect reality. Before `tum run`, the `command` path is checked to exist, be executable, and not be a directory, so a bad definition fails with a clear message instead of launching a pane that dies at once. Instance records whose recorded pane or PID no longer match live tmux — a process that died unnoticed, a restarted server, a reassigned ID — are surfaced as `stale` or `unknown` rather than letting the user act on bad data. When a borrowed instance's host pane is closed (window closed, pane killed) while the association still points at it, the association is flagged as orphaned and reconciled on the next manager operation.

---

## Borrowing

**Purpose.** Borrow is the central gesture; it should land the utility where and how the user wants without producing a broken pane.

A borrow can split the host window vertically or horizontally, set per-borrow or per-definition, so a wide log tail splits sideways while a tall REPL splits below. The borrowed pane's initial size can be set as a percentage (the file manager takes 30%, not 50%) per-borrow or per-definition; a 50/50 default wastes space for tools that need little and starves tools that need a lot, and setting it once per definition makes every later borrow land right. If the target window is too narrow or short for the pane to be usable, the borrow warns or refuses rather than producing a tiny broken pane.

When a target window is needed and the name is not given, the user picks it from an fzf list of candidate sessions and windows with live panes previewed, instead of typing a forgettable, non-unique name. An ordinary pane the user already has running can be adopted into the manager with `tum manage`, which registers the active pane as a utility — creating a definition and instance record from its current command and arguments — so it can be borrowed and returned like any other.

---

## Arguments and configuration

**Purpose.** Utilities need configurable launch behavior (command, args, working directory, scope, lifecycle, colors, environment). Users must be able to set this once in a file, override it per-launch from the CLI, and pass extra arguments to the utility itself — all without the manager re-parsing anything through a shell.

- Definitions and layouts are human-edited.
- Missing required arguments are prompted in declaration order. For a layout restore, all missing values are collected before any tmux mutation. In non-interactive mode, the command fails with the names of the missing values.
- Secret values are supplied interactively or via a secret provider, never stored in config, layouts, or logs. Secret prompts read without echoing, like `read -s`.
- A definition may supply default values for optional arguments, used when no higher-precedence source provides one, so `tum run logs` just works. CLI arguments — after `--`, or via named options — override those defaults per the documented precedence chain; this is what makes ad-hoc variation possible without a new definition. Ad-hoc launches still accept manager options before `--` (`--name`, `--cwd`, `--instance-policy`), defaulting the rest from config, so ad-hoc does not mean unmanaged.
- On validation, unknown config keys (a typo like `instnace_policy`) are reported rather than silently ignored.
- A definition can declare a per-utility key/value environment map applied to its process at launch, scoping tweaks like `PAGER=cat` to one tool. On top of that, named environment profiles (`dev`, `staging`, `prod`) let a utility switch a whole env set — different DB creds, say — without editing the definition. Secrets in a profile still go through the secret provider, never the profile file.

---

## Interactive management

**Purpose.** Interactive management is a major project feature, not an afterthought. But tmux already consumes a prefix key, so the project must avoid demanding a large new family of memorized key combinations.

**How it could work.**

- One popup entry point (`tum popup`) with a compact action list: borrow, return, manage/list instances, start utility, restore/save layout, edit config, diagnostics. Each action delegates to the same CLI command used in scripts — the popup is a control surface, not a second command language. Anything doable in the popup is scriptable, and a CLI fix fixes the UI too.
- fzf is the primary searchable selector when installed; it shows definition, instance ID suffix, state, and current/home location. Multi-select is enabled only for batch-safe actions (batch borrow/return), never for destructive singletons like stop. Without fzf, a numbered readline selector is the fallback, and the core CLI works without it.
- A small number of tmux bindings open the popup. The project does not compete with tmux's navigation, resize, zoom, copy-mode, or window-management bindings.
- Collect all required argument prompts before any batch move or layout restore. Cancelling a prompt leaves tmux state unchanged.
- The popup's width and height are configurable (a percentage of the window or fixed values), so it fits both a large monitor and a laptop.
- A CLI remains available for scripting and direct use; the popup calls CLI commands, never re-implementing them. Each subcommand has a focused `--help` page, generated from metadata, rather than only a global dump.

---

## Appearance

**Purpose.** Borrowed panes can be visually distinguishable so the user knows at a glance which panes are borrowed and what kind they are — but color must be optional and must not be required to understand state.

**How it could work.**

- A borrowed pane's background can be set per-definition, per-launch, or per-instance: `tum color set --instance ID '#263238'`.
- Color changes are scoped to the borrowed pane only and restored or cleared when the resource returns home, unless explicitly configured as persistent. The manager snapshots the original pane options before borrow and restores them on return.
- The implementation accounts for terminal and tmux color capabilities across supported versions.
- An opt-in tmux status-line segment shows a compact manager summary — "2 borrowed", or the active window's borrowed utilities — so the borrow state is ambient without opening the popup.

---

## Layouts

A layout is a named recipe for assembling manager-owned utility panes. It is not a snapshot of the entire tmux window. Ordinary user panes are not layout members and must remain untouched; recording only manager-owned panes is the defining property of a layout and the safety invariant that keeps a restore from overwriting the user's actual work.

### Contents

A layout records utility references, instance policy, pane arrangement relationships among managed panes, destination mode (`current_window` or `separate_window`), optional size proportions, temporary appearance settings, and argument persistence policy. The first version needs a simple ordered split tree, not every possible tmux layout encoding. Proportions (not absolute cell counts) are reapplied on restore so a layout is immediately usable at any window size; they are optional, since some users want panes to fit available space.

### Restore

Resolve all definitions, instances, conflicts, and missing arguments before changing tmux. Add managed panes incrementally into the current window, or create dedicated manager-owned windows. Do not apply a whole-window `select-layout` to a mixed window if that would resize ordinary panes. If a utility is already borrowed, report the conflict rather than silently stealing it.

### Clone

Cloning creates a new layout record and never moves source resources. `shared` items retain shared-instance policy; `per_window` items resolve or create an instance for the destination window; `new_instance` always creates one; `existing_instance` reuses only the explicitly identified instance if valid. Prompt for destination-specific arguments. Do not copy secrets.

### Naming and finding layouts

Each layout has a human name and an optional free-text description, shown in the list and selector, so `tum layout restore NAME` is unambiguous and "which layout was that?" has an answer. Layouts can be tagged by project type (`web`, `data`, `ops`) so the selector can filter to those that fit the current project. The list sorts by most-recently-restored first, since recency beats alphabetical for picking the layout you probably want.

### Saving arguments

Offer `omit` (default), `preset` (named preset reference), or `values` (explicitly approved non-secret values). Secret arguments cannot use `values`.

---

## Workspaces

**Purpose.** Per-window instances and project layouts both need a workspace identity; forcing the user to declare it is friction.

The current workspace is inferred from the shell's current working directory, so per-window instances and layouts auto-associate without explicit naming. Each instance is automatically tagged with the project it was launched or borrowed for, so lists can answer "which utilities belong to project-a?" — and "abandon project-a, reap its instances" becomes a natural operation. This is also the input for suggesting the right layouts automatically.

The simplest implementation is a small script the utility runs to detect the workspace and then start the command.

---

## Implementation constraints

**Purpose.** The project must stay maintainable, composable, and free of unnecessary dependencies — a set of small Unix-style tools, not a monolith.

**How it could work.**

- Small code base; many small utilities with narrow responsibilities and clear input/output contracts. No monolithic blob.
- Bash is preferred. Perl is acceptable for short helpers. Python is not used in runtime code.
- Keep dependencies limited and optional where possible (fzf is optional; `sqlite3` is required).
- Use tmux-native commands for functionality tmux already provides. Do not reimplement pane splitting, resizing, focus, window creation, session switching, or standard navigation.
- Every component must be independently testable.
- All tmux interaction goes through one `tum-tmux` module wrapping `new-session`, `join-pane`, `move-window`, and the rest, so the rest of the code never calls `tmux` directly. tmux-version quirks, quoting, and ID verification then live in one place, and that boundary is the single mock target for tests.
- All metadata read/write goes through one `tum-state` module (`list`/`get`/`put`/`delete`/`recover`), so transactions, locking, and schema rules are implemented once rather than re-implemented or missed in each command.
- Integration tests run against a private tmux server socket (`tmux -L tum-test -f /dev/null`), never the user's default server, so the suite can create and destroy panes freely and stays deterministic.
