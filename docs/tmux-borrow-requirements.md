# tmux-borrow — requirements

## Product overview

### Problem

Power users keep file managers, log followers, REPLs, database consoles, monitors, debuggers, and build watchers running inside tmux. They want to move an already-running utility into the window where they are working and later send it back — without restarting the process and losing its state.

User want to save and restore recurring arrangements base on their current setup, and to have a single interactive interface for managing all of them.

Users want to start utilities with a saved configuration, including required arguments, working directory, and lifecycle policy and layout. Some tmux plugins already offer this, but they do not provide a unified interface for managing multiple utilities.

### Goal

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

## 2. Glossary

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

---

## Core model

These are the fundamental invariants the rest of the requirements build on.

1. A definition may accept positional arguments and named options; one definition may create many instances.
2. Each instance is assigned a home session (manually or by policy) and occupies a full tmux window there.
3. Borrowing moves a pane or window without restarting its process. A pane exists in one window at a time.
4. Any eligible pane in any session can be borrowed — not just managed instances. Manager-owned panes retain identity and return metadata; ordinary panes can be returned/borrowed.
5. Multiple borrowed utilities may coexist in one working window, including from different home sessions.
6. Session names are labels, not keys. Two sessions may share a visible name; the manager distinguishes them by stable internal IDs.
7. The manager owns only what it can prove it owns (record + marker + verified live pane identity).

---

## Functional requirements

| Requirement                  | what it is for | How it could be met           |                                                               |
| ---                          | ---                                            | ---                                                           |
| Register definitions         | name and store utility configs once            | TOML `[utility.NAME]`; `tum define add --wizard\              |
| Launch utility               | start registered utility in its managed home   | `tum run NAME` creates the home window and launches argv      |
| Ad-hoc launch                | run a one-off command with full tracking       | `tum run --name X -- …`; gets a session and stable ID         |
| Multiple instances           | run several copies of one definition           | Each `tum run` creates a new instance with its own ID         |
| Borrow pane                  | bring a running process beside you, no restart | `tum borrow` uses `join-pane` to move the existing pane       |
| Return pane                  | send a borrowed pane back to its home          | `tum return` moves it home and restores appearance            |
| List instances               | see what runs, where, and in what state        | `tum list` shows ID, definition, state, home/current          |
| Selection                    | resolve which instance an action targets       | Auto-select if unique; `--instance ID` or fzf if ambiguous    |
| fzf selector                 | search and pick instances interactively        | `--fzf` flag; multi-select only for batch-safe commands       |
| Required arguments           | avoid launching with missing context           | Prompt before move; fail non-interactively with names         |
| Safe argv                    | prevent injection and argument-boundary loss   | Store as array; never `eval`; no `sh -c` unless user picks    |
| Stop instance                | terminate a managed instance from anywhere     | `tum stop`; targets the instance, never host or ordinary pane |
| Exit policy                  | control what happens when the process exits    | `wait` (default), `shell`, `close`, or `leave`                |
| Save layout                  | capture a borrowed arrangement for reuse       | `tum layout save` records only manager-owned panes            |
| Restore layout               | rebuild without harming ordinary panes         | Incremental add; never wholesale `select-layout` mixed        |
| Config editor                | edit config without knowing its path           | `tum config edit` opens it in `$EDITOR`                       |
| Layout editor                | edit a named layout without its path           | `tum layout edit NAME` opens it in `$EDITOR`                  |
| Wizard/template              | make registration approachable                 | `--wizard` (readline Q&A) or `--template` (append block)      |
| Clone layout                 | reuse for another project, no source moves     | `tum layout clone SRC DEST`; shared reuse, per-window create  |
| Per-window instances         | tie an instance to one window                  | Stable workspace record; create one if none exists            |
| Shared instances             | reuse one instance across windows              | One borrow at a time; enforced transactionally                |
| Window borrow                | move a complete managed window                 | `tum borrow --as window` uses `move-window`                   |
| Host association             | link borrowed pane to its host                 | Record host pane ID; reconcile on next manager op             |
| Lifecycle hooks              | react to idle/borrow/return/stop               | Optional executable+argv hooks; failures reported             |
| Temporary appearance         | mark borrowed panes visually                   | Snapshot styles before borrow; restore on return              |
| Argument presets             | save named argument sets                       | `[preset.UTILITY.NAME]` blocks; referenced by layouts         |
| Bash completion              | complete commands and names                    | `tum-completion` helper sourced from `.bashrc`                |
| Tree selector                | show sessions/windows/instances                | fzf tree view; optional, only if justified                    |
| Argument save policy         | control what a layout stores                   | `omit` (default), `preset`, or `values` (non-secrets)         |
| Recovery                     | reconcile after interruption                   | `tum doctor` vs live tmux; offers repair, no silent discard   |

---

## Arguments and configuration

**Purpose.** Utilities need configurable launch behavior (command, args, working directory, scope, lifecycle, colors, environment). Users must be able to set this once in a file, override it per-launch from the CLI, and pass extra arguments to the utility itself — all without the manager re-parsing anything through a shell.

- Definitions and layouts are human-edited.
- Missing required arguments are prompted in declaration order. For a layout restore, all missing values are collected before any tmux mutation. In non-interactive mode, the command fails with the names of the missing values.
- Secret values are supplied interactively or via a secret provider, never stored in config, layouts, or logs.

## Interactive management

**Purpose.** Interactive management is a major project feature, not an afterthought. But tmux already consumes a prefix key, so the project must avoid demanding a large new family of memorized key combinations.

**How it could work.**

- One popup entry point (`tum popup`) with a compact action list: borrow, return, manage/list instances, start utility, restore/save layout, edit config, diagnostics. Each action delegates to the same CLI command used in scripts — the popup is a control surface, not a second command language.
- fzf is the primary searchable selector when installed; display definition, instance ID suffix, state, and current/home location. Multi-select is enabled only for batch-safe actions. Without fzf, a numbered readline selector is the fallback. The core CLI must work without fzf.
- A small number of tmux bindings open the popup. The project should not compete with tmux's navigation, resize, zoom, copy-mode, or window-management bindings.
- Collect all required argument prompts before any batch move or layout restore. Cancelling a prompt must leave tmux state unchanged (side-effect-free cancellation).
- A CLI remains available for scripting and direct use; the popup calls CLI commands, never re-implementing them.

---

## Appearance

**Purpose.** Borrowed panes can be visually distinguishable so the user knows at a glance which panes are borrowed and what kind they are — but color must be optional and must not be required to understand state.

**How it could work.**

- A borrowed pane's background can be set per-definition, per-launch, or per-instance: `tum color set --instance ID '#263238'`.
- Color changes are scoped to the borrowed pane only and restored/cleared when the resource returns home, unless explicitly configured as persistent. The manager snapshots the original pane options before borrow and restores them on return.
- The implementation accounts for terminal and tmux color capabilities across supported versions.

---

## Layouts

A layout is a named recipe for assembling manager-owned utility panes. It is not a snapshot of the entire tmux window. Ordinary user panes are not layout members and must remain untouched.

### Contents

A layout records utility references, instance policy, pane arrangement relationships among managed panes, destination mode (`current_window` or `separate_window`), optional size proportions, temporary appearance settings, and argument persistence policy. The first version needs a simple ordered split tree, not every possible tmux layout encoding.

### Restore

Resolve all definitions, instances, conflicts, and missing arguments before changing tmux. Add managed panes incrementally or create dedicated manager-owned windows. Do not apply a whole-window `select-layout` to a mixed window if that would resize ordinary panes. If a utility is already borrowed, report the conflict rather than silently stealing it.

### Clone

Cloning creates a new layout record and never moves source resources. `shared` items retain shared-instance policy; `per_window` items resolve/create an instance for the destination window; `new_instance` always creates one; `existing_instance` reuses only the explicitly identified instance if valid. Prompt for destination-specific arguments. Do not copy secrets.

### Saving arguments

Offer `omit` (default), `preset` (named preset reference), or `values` (explicitly approved non-secret values). Secret arguments cannot use `values`.

---

## Implementation constraints

**Purpose.** The project must stay maintainable, composable, and free of unnecessary dependencies — a set of small Unix-style tools, not a monolith.

**How it could work.**

- Small code base; many small utilities with narrow responsibilities and clear input/output contracts. No monolithic blob.
- Bash is preferred. Perl is acceptable for short helpers. Python is not used in runtime code.
- Keep dependencies limited and optional where possible (fzf is optional; `sqlite3` is required).
- Use tmux-native commands for functionality tmux already provides. Do not reimplement pane splitting, resizing, focus, window creation, session switching, or standard navigation.
- Every component must be independently testable.

