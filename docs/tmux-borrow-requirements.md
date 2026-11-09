# tmux-borrow — requirements

## Product overview

### Problem

Power users keep file managers, log followers, REPLs, database consoles, monitors, and debuggers running inside tmux. They want to move an already-running utility into the window where they are working, hide it out of the way, bring it back, and close it — all with single keys — without restarting the process and losing its state. They want to assemble groups of utilities into named layouts, hand a utility off to another session and back, and adopt any existing pane as a temporary utility.

Users want to save and restore recurring arrangements based on their current setup, and to have a single interactive interface for managing all of them.

Users want to start utilities with a saved configuration, including required arguments, working directory, and layout. Some tmux plugins already offer this, but they do not provide a unified interface for managing multiple utilities.

### Goal

A small orchestration layer over tmux that keeps all state in tmux itself (no external database), borrows utilities and layouts into any host pane, toggles them in and out with slot-key shortcuts, closes them by killing the pane, and composes working sets with push/pop and import. tmux-borrow is a superset of tmuxake's side-pane model: the same hide/show/close flow, generalized to named utilities, layouts, multiple instances, import, and a pluggable chooser.

Specifically:

- Define utilities and layouts as flat files and borrow them beside the current host pane.
- Support multiple instances of one utility.
- Park borrowed panes in a hidden session and bring them back without restarting the process.
- Toggle any borrowed thing in and out with single-key flip-flop via slot keys.
- Push borrowed panes onto a stack and pop them into any host to compose working sets.
- Import any existing tmux pane as a temporary or named utility.
- Borrow layouts (groups of utilities) with per-member and group slots.
- Prompt for missing required arguments before mutating tmux.
- Keep all state in tmux pane-scope options — no external database.
- Route interactive choices through a pluggable external chooser.
- Keep the implementation small and split into independent commands.

### Non-goals

- Reimplement tmux navigation, zoom, resizing, splitting, or session management.
- Display one pane in multiple windows simultaneously (a pane exists in one window at a time).
- General-purpose process checkpointing or migration.
- Manage ordinary panes as utilities unless explicitly imported.

---

## Glossary

| Term              | Meaning                                                                                                                                      |
| ---               | ---                                                                                                                                          |
| Utility           | A single-pane runnable command managed as a movable tmux resource (`htop`, `lazygit`, a log tail, REPL). Always one pane.                    |
| Layout            | A named group of utility references and their arrangement. Contains multiple utilities; a utility is never multi-pane.                       |
| Instance          | One running pane of a utility. One definition may have many instances.                                                                       |
| Definition        | A saved configuration file describing a utility or a layout. Flat `key:value`; the filename is the name.                                     |
| Host pane         | The pane beside which a utility or layout is borrowed. Recorded on the borrowed pane as a pane-scope option.                                 |
| Borrow            | Attach a utility or layout instance beside the current host pane, creating it first if it does not exist.                                    |
| Hide (return)     | Park a borrowed pane in the hidden session, clearing its host binding. Non-destructive; the pane stays alive.                                |
| Show              | Bring a hidden pane back beside its host, restoring its geometry.                                                                            |
| Flip-flop         | Toggle a borrowed thing between shown and hidden via its slot key.                                                                           |
| Close             | `kill-pane`. Destroys the pane and all its state. Context-aware: works from the borrowed pane or the host.                                   |
| Push / pop        | LIFO stack: push detaches a borrowed pane onto the stack (no host); pop attaches the top to the current host.                                |
| Import            | Adopt an existing tmux pane as a utility. Anonymous (temporary) or named (saved to a definition file).                                       |
| Hidden session    | The single shared session where hidden and pushed panes park. Name configurable via the `@tum-hidden-session` option (default `tum-hidden`). |
| Slot              | A single-character key assigned to a borrowed thing (utility, layout, or layout member) for flip-flop.                                       |
| Chooser           | The external interactive selector script, called via a defined API. `--interactive` routes through it.                                       |
| Pane-scope option | A tmux user option (`@tum-*`) set on a pane with `-p`. The state store; survives `move-pane`; dies with the pane.                            |
| Orphan            | A half-dead binding: the host pane is gone but the utility pane is alive. Marked `!`, left in place.                                         |
| Tag               | A free-form marker on a utility definition, usable as a borrow selector.                                                                     |

---

## Core model

- State lives entirely on panes as pane-scope `@tum-*` user options. No external database, no index file. The hidden session's pane list (queried via `tmux list-panes -a`) is the complete state.
- A utility is always one pane. A layout is a group of utilities; borrowing a layout borrows all its members into the same host window.
- Borrowing moves a pane with `join-pane`/`move-pane`; the process is moved, not restarted.
- Multiple utilities and multiple layouts may be attached to one host simultaneously.
- Multiple instances of one utility are allowed and wanted.
- Closing a pane (kill-pane) kills its state — full-dead cleanup is automatic. Half-dead (host gone, utility alive) is an orphan, left in place and marked.
- The manager owns only what it can prove it owns: a `@tum-*` pane-scope option and a verified live pane id.

---

## State representation

Each utility pane carries its state in pane-scope user options:

| Option          | Meaning                                                            |
| ---             | ---                                                                |
| `@tum-util`     | Utility name (the definition filename).                            |
| `@tum-host`     | Host pane id; empty when hidden or pushed.                         |
| `@tum-layout`   | Layout id; empty for a standalone utility.                         |
| `@tum-slot`     | Slot key for flip-flop.                                            |
| `@tum-geometry` | Last-used width and height, captured at hide, restored on show.    |
| `@tum-tags`     | Comma-separated tags from the definition.                          |
| `@tum-source`   | `defined`, `imported-anon`, or `imported-named`.                   |
| `@tum-pushed`   | Present (with `@tum-push-seq`) when the pane is on the push stack. |

- Pane-scope options survive `move-pane` and `join-pane` across sessions. They die with the pane, so a killed utility leaves nothing to clean up.
- Hidden panes park as windows in the hidden session. Their identity is the pane options, not the window name; the window name is cosmetic.
- The host window records its attached slots in a window-scope option `@tum-host-slots` — a comma-separated list of `slot:pane-id` pairs — so hide/close/flip from the host resolves without scanning panes. It is updated on every borrow/hide/close/push/pop and is a cache of the pane-scope `@tum-slot`/`@tum-host` truth, never the source of truth itself.
- No PID is stored as a binding key. PID is read ephemerally at import time only, to capture the pane's command, cwd, and environment.
- The hidden session's name is the global option `@tum-hidden-session` (default `tum-hidden`). The session is created on demand if it does not exist; hidden and pushed panes park as windows inside it.

---

## Definitions

- One file per utility (`<name>.util`) and one file per layout (`<name>.layout`), in one directory: `~/.config/tum/` (`XDG_CONFIG_HOME` respected). Utilities and layouts share the directory.
- Flat `key:value` format, no sections, no hierarchy — simple to parse in bash.
- The filename is the name. There is no `name:` field inside the file, so collisions are impossible.
- Layouts reference utility files by name; no repetition.

### Utility file keys

| Key       | Required | Meaning                                                                                 |
| ---       | ---      | ---                                                                                     |
| `command` | yes      | Executable path or name.                                                                |
| `args`    | no       | Arguments to the command.                                                               |
| `cwd`     | no       | Working directory.                                                                      |
| `env`     | no       | Comma-separated `KEY=VALUE` pairs applied at launch (e.g. `PGPASSWORD=secret,FOO=bar`). |
| `tags`    | no       | Comma-separated tags.                                                                   |
| `slot`    | no       | Default slot key; auto-assigned on conflict.                                            |

### Layout file keys

| Key         | Required | Meaning                                                      |
| ---         | ---      | ---                                                          |
| `layout_id` | no       | Layout id stamped on member panes. Defaults to the filename. |

Member entries are not a `members:` key — see the DSL below.

### Layout DSL

A layout file is flat `key:value`, like a utility file — no `members:` wrapper, no indentation, no hierarchy. Every line is a top-level `key:value` entry parsed by the same single `while IFS=: read` loop. One key is special:

- `layout_id` — optional; the layout id stamped on member panes (defaults to the filename).

Every other key is a **member entry**. The key is the member name (it must match a utility definition filename); the value is its placement:

```
<member-name>: anchor=<host|member-name>, side=<right|left|top|bottom>, size=<N%|Nc>
```

A complete layout file:

```
layout_id: dev
editor: anchor=host, side=right, size=60%
term: anchor=host, side=bottom, size=20%
logs: anchor=term, side=bottom, size=30%
```

- `anchor` defaults to `host`. A member may anchor to another member, allowing two panes on the same side of the host (for example, editor right of host, logs below editor).
- `side` is required.
- `size` is a percentage of the anchor or a cell count; optional.

---

## Arguments and configuration

**Purpose.** Utilities need configurable launch behavior — command, arguments, working directory, and environment — set once in the definition file and overridable per-borrow from the CLI, all without the manager re-parsing anything through a shell.

- Definitions are human-edited flat `key:value` files (see Definitions). Layouts reference utilities by name and carry no arguments of their own.
- Missing required arguments are prompted in declaration order. For a layout borrow, all missing values are collected before any tmux mutation. In non-interactive mode, the command fails with the names of the missing values.
- Secret values are supplied interactively or via a secret provider, never stored in definition files, layouts, or logs. Secret prompts read without echoing, like `read -s`.
- A definition may supply default `args`; extra arguments passed after `--` on the command line override or extend them, so a one-off variation does not require a new definition file.
- The `cwd` and `env` keys are applied at launch; CLI flags override them per-borrow.
- On validation, unknown definition keys (a typo like `arg`) are reported rather than silently ignored.
- Safe argv: arguments are stored and launched as an ordered array, so argument boundaries are preserved. No `eval`, no `sh -c` unless the user explicitly selects a shell as the executable.

---

## Borrowing

Borrow is the primary action: attach a utility or layout beside the current host pane, creating it first if it does not exist.

### Modes

| Mode     | Command                        | Behavior                                                                                                                 |
| ---      | ---                            | ---                                                                                                                      |
| Default  | `tum borrow <util>`            | Borrow hidden instance bound to this host; else existing hidden (chooser if several); else create and borrow.            |
| New      | `tum borrow --new <util>`      | Always create a fresh instance, then borrow it.                                                                          |
| Existing | `tum borrow --existing <util>` | Only borrow an existing instance; error or chooser if none.                                                              |
| By tag   | `tum borrow --tag <tag>`       | Borrow by tag; resolution as default mode.                                                                               |
| No name  | `tum borrow`                   | Chooser over all utilities and layouts. Uninstantiated picks create and borrow; instantiated picks borrow that instance. |

Layouts follow the same modes. `--new` on a layout creates fresh member instances.

### Resolution order (default mode)

1. An instance already bound to this host (`@tum-host` equals the current pane id) — borrow it.
2. Else, hidden instances of this utility exist — borrow one (chooser if several). An orphan — whose `@tum-host` points at a dead pane — counts as hidden here; re-borrowing it clears the dead binding and sets the new host.
3. Else, create an instance and borrow it.

### Host binding

On borrow, the borrowed pane's `@tum-host` is set to the current pane id, and the host window records the slot. On hide or push, `@tum-host` is cleared.

---

## Flip-flop (hide / show)

Flip-flop toggles a borrowed thing between shown and hidden. It is generic — it does not name a utility, it acts on a slot. The CLI command is `tum flip`: `tum flip <slot>` toggles by slot, `tum flip` toggles the focused borrowed pane, and `tum flip --interactive` opens the chooser for a host with several attached things.

### Slot keys

Every borrowed thing — a utility instance, a layout group, or each member of a borrowed layout — gets a slot key, declared in its definition or auto-assigned on conflict. One slot is one flip-flop target. A layout's slot toggles all its members as a group; a member's slot toggles just that member.

### Shortcuts
| Action             | Shortcut                          | Behavior                                                                                   |
| ---                | ---                               | ---                                                                                        |
| Toggle by slot     | `<prefix> H <slot>`               | Hide if shown, show if hidden. A layout slot toggles all members together.                 |
| Toggle focused     | `<prefix> H`                      | From a focused borrowed pane: toggle just that pane.                                       |
| Toggle via chooser | `<prefix> H` with `--interactive` | Open the chooser to pick which attached thing to toggle, for a host with several attached. |

- Hiding a layout member parks it in the hidden session but keeps its `@tum-layout`; re-showing the layout brings it back.
- Geometry is captured at hide and restored at show.

---

## Hide and close

Two distinct actions with different shortcuts. Hide is non-destructive and reached through flip-flop (`tum flip`, above); close is destructive and is its own command, `tum close` — a context-aware `kill-pane` (see below). When a pane is closed, it is gone and tmux-borrow does nothing further with it; there is no exit-policy hook.

| Action        | What it does                                                              | State after                                         |
| ---           | ---                                                                       | ---                                                 |
| Hide (return) | `move-pane` to the hidden session; clear `@tum-host`; keep `@tum-layout`. | Pane alive, parked, still a layout member.          |
| Close         | `tum close` → `kill-pane`.                                                | Pane and all its `@tum-*` options gone. No cleanup. |

- Close works in a layout: a closed member is gone from the group; the other members continue. The layout id on remaining members is unchanged.
- There is no "layout instance" — the layout is just an id stamped on member panes. Closing a member does not affect the definition or other members.
- Close is context-aware (see below); hide is slot-keyed (via flip-flop) or focused.

### Close (context-aware)

| Focused pane                        | Action                                 |
| ---                                 | ---                                    |
| A borrowed pane                     | Close it.                              |
| A host with one borrowed thing      | Close that thing.                      |
| A host with several borrowed things | Open the chooser; close the selection. |

No confirmation — close is a simple, immediate `kill-pane`, mirroring tmuxake.

---

## Push and pop

Push/pop is a separate command family — not bridged to layouts, save-layout, or any other command.

| Action | Command    | Behavior                                                                                                                 |
| ---    | ---        | ---                                                                                                                      |
| Push   | `tum push` | Detach the focused borrowed pane onto a LIFO stack. Records geometry and push-seq; clears host. Pushed pane has no host. |
| Pop    | `tum pop`  | Attach the highest-`@tum-push-seq` pane to the current host at its recorded geometry. Consumes it from the stack.        |

- The stack is `list-panes -a` filtered by `@tum-pushed`, sorted by `@tum-push-seq` descending. Non-contiguous sequence numbers are fine — panes may be closed between pushes.
- Push from the borrowed pane directly. From the host, present the chooser when more than one utility is borrowed.
- Pop attaches at the geometry recorded at push time.
- A user can compose a working set by pushing several utilities from anywhere, then popping them one by one into a host.

---

## Import

Adopt an existing tmux pane as a utility.

| Flavour | Command             | Behavior                                                                                                                                                                         |
| ---     | ---                 | ---                                                                                                                                                                              |
@| Anonymous | `tum import`        | Make the current pane a temporary utility. No file written. `@tum-source=imported-anon`, `@tum-util` set to an auto-generated name (`import-<pane-id>`) so the chooser can list it. Gone when closed or when the server dies. |
| Named   | `tum import <name>` | Capture command, args, cwd, env (max fidelity, from `/proc/$pid/`) and write a `<name>.util` file. `@tum-source=imported-named`, `@tum-util=<name>`. Editable; a normal utility. |

- Anonymous import is borrowable, hideable, and closeable like any utility, but is not saved.
- Named import captures as much as possible; the resulting definition file is meant to be hand-edited to refine.

---

## Layouts

- A layout is a named group of utilities. Borrowing a layout borrows all its members into the host window at their declared positions.
- `tum borrow <layout>` (default mode): borrow an existing hidden group bound to this host if any; else an existing hidden group (chooser if several); else create one.
- `tum borrow --new <layout>`: always create fresh member instances.
- Members may anchor to the host or to another member, allowing arbitrary trees on one side of the host.
- Each member gets its own slot for individual flip-flop; the layout group gets a slot for group flip-flop.
- Hiding a member keeps `@tum-layout`; re-showing the layout brings it back.
- Closing a member removes it from the group; the layout id on survivors is unchanged. There is no layout instance to repair.

### Borrowing a layout (restore rules)

- Resolve all member definitions, missing arguments, and conflicts before changing tmux.
- Add member panes incrementally beside the host and beside anchoring members. Never apply a whole-window `select-layout` to the host window if that would resize ordinary panes.
- If a member utility is already borrowed elsewhere, report the conflict rather than silently stealing it.
- Collect every required argument before the first `join-pane`; a cancelled prompt leaves tmux state unchanged.

---

## Chooser

The `--interactive` flag routes any choice through an external chooser script via a defined API.

### Contract

```
tum-chooser <prompt> <items_file> <output_file>
```

- Reads items (one per line) from `items_file`.
- Writes the selection (one line) to `output_file`.
- Exit 0 means a selection was written; non-zero means cancelled (output file empty).
- The chooser renders its own UI. In popup mode, tmux-borrow runs it inside `display-popup` with stdin and stdout redirected to the files — the popup PTY does not carry the caller's stdin or stdout, so files are the bridge.
- The `@tum-chooser` tmux option selects the script (default `tum-chooser` on PATH). An fzf-based implementation ships as the reference; any script following the contract is a drop-in replacement.

### Why files, not FIFOs

The data is small and one-shot. Files persist for debugging; FIFOs offer no advantage for short-lived, bounded interaction and cannot be inspected after the fact.

---

## Status glyphs

Two configurable glyphs, with defaults resembling tmuxake's:

| Pane                      | Glyph                                                          | Meaning                                                 |
| ---                       | ---                                                            | ---                                                     |
| Host with borrowed things | `÷` (configurable via `@tum-host-glyph`)                       | This pane has utilities or layouts attached.            |
| Borrowed pane             | `§` (configurable via `@tum-borrowed-glyph`) plus utility name | This is a borrowed utility.                             |
| Orphan (host gone)        | `!` prefix                                                     | The host pane is dead; the utility is alive and parked. |

- Surfaced in the tmux status bar and the bash prompt via `tum status`.

---

## Listings (`tum ls`)

`tum ls` lists all utility panes across all sessions, queried from `list-panes -a`:

| Column   | Source                                                         |
| ---      | ---                                                            |
| Utility  | `@tum-util`                                                    |
| Layout   | `@tum-layout`                                                  |
| Host     | `@tum-host` (session:pane, or `hidden`, `host gone`, `pushed`) |
| Slot     | `@tum-slot`                                                    |
| Geometry | `@tum-geometry`                                                |
| State    | shown, hidden, pushed, or orphan                               |

- Global view: any session can borrow; `tum ls` shows where every instance lives and what it is bound to.

---

## Orphan handling

Lazy and manual, tmuxake-style. No proactive hooks on pane death.

| Condition                | Detection                                     | Action                                                                               |
| ---                      | ---                                           | ---                                                                                  |
| Host dead, utility alive | `@tum-host` pane id is not in `list-panes -a` | Leave binding intact; mark `!`; show "host gone". User hides or re-borrows to clear. |
| Utility dead (full-dead) | Pane is gone from `list-panes -a`             | Nothing to do — state died with the pane. Automatic.                                 |

- `tum check` lists half-orphans for the user to act on.
- No auto-return. Detection is not a hide action; the binding stays until the user decides.

---

## Command summary

Every `tum` command, with its arguments. Behavior is defined in the sections above; this table is the index.

| Command             | Arguments                   | Behavior                                                                                                                              |
| ---                 | ---                         | ---                                                                                                                                   |
| `tum borrow`        | `[<util or layout>]`, modes | Attach beside the current host pane; create first if needed. Modes: default, `--new`, `--existing`, `--tag <tag>`, no-name (chooser). |
| `tum flip`          | `[<slot>]`, `--interactive` | Toggle a borrowed thing by slot, or the focused pane, or via the chooser.                                                             |
| `tum close`         | (none — context-aware)      | `kill-pane` the focused borrowed pane, or the host's single borrowed thing, or chooser-pick among several.                            |
| `tum push`          | (none)                      | Detach the focused borrowed pane onto the LIFO stack.                                                                                 |
| `tum pop`           | (none)                      | Attach the top of the stack to the current host.                                                                                      |
| `tum import`        | `[<name>]`                  | Adopt the current pane as a utility — anonymous (no name) or named (writes `<name>.util`).                                            |
| `tum ls`            | (none)                      | List all utility panes across all sessions.                                                                                           |
| `tum check`         | (none)                      | List orphans (host dead, utility alive).                                                                                              |
| `tum status`        | `[<pane_id>]`               | Emit the glyph string for a pane (for the tmux status bar; tmux interpolates `#{pane_id}`).                                           |
| `tum prompt`        | (none)                      | Emit the PS1 glyph snippet for the shell prompt.                                                                                      |
| `tum popup`         | (none)                      | Open the full interactive menu (every command reachable).                                                                             |
| `tum cheatsheet`    | (none)                      | Open a popup listing every key binding.                                                                                               |
| `tum bindings tmux` | (none)                      | Generate the tmux `bind-key` fragment from the `@tum-*` options.                                                                      |
| `tum-chooser`       | `<prompt> <items> <out>`    | The external chooser script (the `--interactive` backend); fixed contract, not a `tum` subcommand.                                    |

`tum popup`, `tum cheatsheet`, and `tum bindings tmux` are conveniences over the commands above; the keymap document defines the bindings they support.

---

## Implementation constraints

- Small code base; many small utilities with narrow responsibilities and clear input/output contracts. No monolith.
- Bash preferred; Perl acceptable for short helpers. No Python in runtime code.
- No sqlite, no external database. State is in tmux pane-scope options.
- The chooser is an external script; fzf is one implementation, not a dependency of the core. The core works without any chooser installed (commands that need a chooser fall back to erroring or to a numbered list).
- All tmux interaction goes through one `tum-tmux` module wrapping `new-session`, `join-pane`, `move-pane`, `move-window`, and the rest. The rest of the code never calls `tmux` directly. tmux-version quirks, quoting, and pane-id verification live in one place.
- All state read/write goes through one `tum-state` module that wraps pane-scope option get, set, and scan, so the encoding rules are implemented once.
- Before borrow, the `command` path is checked to exist and be executable, so a bad definition fails with a clear message instead of launching a pane that dies at once.
- Bash completion completes commands, utility names, and layout names.
- Integration tests run against a private tmux server socket (`tmux -L tum-test -f /dev/null`), never the user's default server.
- tmux ≥ 3.2 is required: pane-scope user options (the state store) need tmux 3.0, and `display-popup` (the chooser/prompt overlay) needs tmux 3.2. State the floor in the README.
