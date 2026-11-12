# tmux-borrow — requirements

## Product overview

### Problem

Power users keep file managers, log followers, REPLs, database consoles, monitors, and debuggers running inside tmux. They want to move an already-running utility into the window where they are working, hide it out of the way, bring it back, and close it — all with single keys — without restarting the process and losing its state. They want to assemble groups of utilities into named layouts, hand a utility off to another session and back, and adopt any existing pane as a temporary utility.

Users want to save and restore recurring arrangements based on their current setup, and to have a single interactive interface for managing all of them.

Users want to start utilities with a saved configuration, including required arguments, working directory, and layout. Some tmux plugins already offer this, but they do not provide a unified interface for managing multiple utilities.

### Goal

A small orchestration layer over tmux that keeps all dynamic state in a tmux pane attribute, borrows utilities and layouts into any host pane, toggles them in and out with slot-key shortcuts, closes them by killing the pane, and composes working sets with push/pop and import. tmux-borrow is a superset of tmuxake's side-pane model: the same hide/show/close flow, generalized to named utilities, layouts, multiple instances, import, and a pluggable chooser.

Specifically:

- Define utilities and layouts as flat files and borrow them beside the current host pane.
- Support multiple instances of one utility.
- Park borrowed panes in a hidden session and bring them back without restarting the process.
- Toggle any borrowed thing in and out with single-key flip-flop via slot keys.
- Push borrowed panes onto a stack and pop them into any host to compose working sets.
- Import any existing tmux pane as a temporary or named utility.
- Borrow layouts (groups of utilities) with per-member and group slots.
- Prompt for user-input arguments at create time before mutating tmux.
- Keep all dynamic state in a tmux pane attribute; keep only static configuration in `@tum-*` options.
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
| Host pane         | The pane beside which a utility or layout is borrowed. Recorded in the borrowed pane's state (`host` field).                                |
| Borrow            | Attach a utility or layout instance beside the current host pane, creating it first if it does not exist.                                    |
| Hide (return)     | Park a borrowed pane in the hidden session, clearing its host binding. Non-destructive; the pane stays alive.                                |
| Show              | Bring a hidden pane back beside its host, restoring its geometry.                                                                            |
| Flip-flop         | Toggle a borrowed thing between shown and hidden via its slot key.                                                                           |
| Close             | `kill-pane`. Destroys the pane and all its state. Context-aware: works from the borrowed pane or the host.                                   |
| Push / pop        | LIFO stack: push detaches a borrowed pane onto the stack (no host); pop attaches the top to the current host. Independent of the pool/owned distinction — a push/pop moves a pane regardless of who owns it. |
| Import            | Adopt an existing tmux pane as a utility. Anonymous (temporary) or named (saved to a definition file).                                       |
| Hidden session    | The single shared session where hidden and pushed panes park. Name configurable via the `@tum-hidden-session` option (default `tum-hidden`). |
| Slot              | A single-character key in the range `0–9` or `a–z`, assigned to a borrowed thing for flip-flop. Slot keys are unique within a host window.   |
| Chooser           | The external interactive selector script, called via a defined API. Invoked implicitly when a command must choose among several candidates. |
| State store       | The tmux attribute that carries a managed pane's dynamic state: the pane title (`select-pane -T`), chosen by the viability test (Alternative A). A pane-scope `@tum-state` user option (Alternative B) is the documented fallback, isolated behind one `tum-state` function group; both encode the same `tum:` field string. |
| Orphan            | A half-dead binding: the host pane is gone but the utility pane is alive. Marked `!`, left in place.                                         |
| Pool utility      | An instance with no home host. Any host can borrow it. Created by `tum borrow` (create branch).                                              |
| Owned utility     | An instance bound to a home host (the pane that created it via `tum new`). Flip-flop returns it only to its home.                            |
| Special key       | A reserved key in a definition file (`command`, `args`, `cwd`, `slot`, `input`, `use-process-env` for utilities; `layout_id`, `focus` for layouts). In a utility file, every other key is an environment key; in a layout file, every other key is a member entry. |
| Environment key   | A non-special key in a utility definition file; its value sets an environment variable for the launched process.                             |

---

## Core model

- Dynamic state lives in the pane title as a structured `tum:` string (Alternative A, chosen by the viability test — see State representation). Static configuration lives in `@tum-*` tmux options. There is no external database, no index file. The hidden session's pane list (queried via `tmux list-panes -a`) is the complete state. The store choice is isolated behind one `tum-state` function group, so a switch to the `@tum-state` pane-scope option (Alternative B) touches that group and nothing else.
- A utility is always one pane. A layout is a group of utilities; borrowing a layout borrows all its members into the same host window.
- Borrowing moves a pane with `join-pane`/`move-pane`; the process is moved, not restarted.
- Multiple utilities and multiple layouts may be attached to one host simultaneously.
- Multiple instances of one utility are allowed and wanted.
- Closing a pane (kill-pane) kills its state — full-dead cleanup is automatic. Half-dead (host gone, utility alive) is an orphan, left in place and marked.
- The manager owns only what it can prove it owns: a recognized `tum:` state string on a verified live pane id.

---

## State representation

### Requirement

Dynamic per-pane state must live in tmux itself — no external database, no index file — and it must be kept strictly separate from static configuration. The hidden session's pane list (queried via `tmux list-panes -a`) is the complete state.

The store is **Alternative A — the pane title** (`select-pane -T` / `#{pane_title}`), chosen by the viability test (see below): no tested target utility clobbered a set title. A pane-scope `@tum-state` user option (Alternative B) is the documented fallback, isolated behind one `tum-state` function group; both encode the same fields, so the rest of the code is identical either way and a switch touches only that group.

### State fields

Whichever store is chosen, every managed pane carries these fields, encoded as a `tum:`-prefixed, semicolon-separated `key=value` string:

```
tum:util=<name>;host=<pane-id>;home=<pane-id>;slot=<key>;geom=<WxH>;src=<source>;lay=<layout-id>;push=<seq>
```

| Field  | Meaning                                                                                | Empty when                                |
| ---    | ---                                                                                    | ---                                       |
| `util` | Utility name (the definition filename).                                               | never (a borrowed pane always names it)   |
| `host` | Current host pane id.                                                                  | hidden or pushed                          |
| `home` | The creating host pane id (owned utilities). Empty for pool utilities.                | pool utility                              |
| `slot` | Slot key (`0–9`, `a–z`) for flip-flop. Unique within a host window.                    | never (auto-assigned at create)           |
| `geom` | Last width and height as `WxH`, captured at hide and push, restored on show and pop.   | not yet hidden or pushed                  |
| `src`  | `defined`, `imported-anon`, or `imported-named`.                                      | never                                     |
| `lay`  | Layout id; empty for a standalone utility.                                             | standalone utility                        |
| `push` | Push sequence number; present only when the pane is on the push stack.                | not on the stack                          |

The `tum:` prefix lets tmux-borrow tell its own panes apart from ordinary panes. A pane whose store does not carry the `tum:` prefix is not managed.

**Geometry is touched only when a tum command runs** (hide, show, push, pop). No process watches panes continuously, so a live resize of a shown pane does not update `geom`; the new size is captured at the next hide or push and restored at the next show or pop.

### Chosen store — Alternative A (pane title)

The string is stored in the pane's title, set with `select-pane -T` and read with `#{pane_title}`.

- **Pros:** the pane title has existed since tmux 1.x; it is a pane attribute and travels with the pane across `move-pane`/`join-pane`, including across sessions; no version bump for state.
- **Cons:** many terminal programs set the pane title themselves through escape sequences (`htop`, `vim`, `less`, `man`, `lazygit`, most curses apps). When they do, they overwrite the `tum:` string and tmux-borrow loses that pane's state. There is no per-pane tmux option that prevents programs from setting the title. The viability test below checks whether the target utilities actually do this.

### Fallback — Alternative B (pane-scope `@tum-*` user option)

Store the string in a pane-scope user option, set with `tmux set-option -p @tum-state '<string>'` and read with `show-options -p`. Programs cannot overwrite tmux user options, so the state is safe from curses applications; pane options travel with the pane across moves, like the title does. Pane-scope options require tmux 3.0+ (the title needs only 1.x); reading and writing is slightly more verbose. The project already requires tmux ≥ 3.2, so B is available if ever needed. **B is not used today**; it exists as a one-function-group switch should a real-world target later clobber the title (the failure mode is silent state loss).

### Viability test — result

The choice turned on one question: do the utilities tmux-borrow is meant to manage overwrite the pane title? Run against a private tmux server (`tmux -L tum-test -f /dev/null`): for each utility in a representative set, create a pane, set its title to `tum:probe=1`, launch the utility, wait two seconds, read `#{pane_title}`, and record whether it still starts with `tum:`. A utility that leaves the title intact passes; one that overwrites it fails.

**Result (run with tmux 3.5a, `make viability`):** `htop`, `vim`, `less`, `tail`, and `bash` all preserved a set title; `man` uses `less` as its pager (which preserved), so it is covered transitively. No tested target utility clobbered the title, so Alternative A is viable and is the chosen store. `tum-state` reads and writes via `select-pane -T` / `display-message -p '#{pane_title}'`. If a real-world target later clobbers, switch to B inside `tum-state` and nowhere else.

### Static configuration options (`@tum-*`)

| Option                | Default       | Meaning                                                        |
| ---                   | ---           | ---                                                            |
| `@tum-chooser`        | `tum-chooser` | The chooser script on PATH.                                    |
| `@tum-host-glyph`     | `÷`           | Glyph shown on a host pane with borrowed things attached.     |
| `@tum-borrowed-glyph` | `§`           | Glyph shown on a borrowed pane (plus utility name).           |
| `@tum-hidden-session` | `tum-hidden`  | Name of the shared session where hidden and pushed panes park. |

The hidden session is created on demand if it does not exist; hidden and pushed panes park as windows inside it.

No PID is stored as a binding key. PID is read ephemerally at import time only, to capture the pane's command, cwd, and environment.

---

## Definitions

- One file per utility (`<name>.util`) and one file per layout (`<name>.layout`), in one directory: `~/.config/tum/` (`XDG_CONFIG_HOME` respected). Utilities and layouts share the directory.
- Flat `key:value` format, no sections, no hierarchy — simple to parse in bash.
- The filename is the name. There is no `name:` field inside the file, so collisions are impossible.
- Layouts reference utility files by name; no repetition.
- Comments: everything after `#` on a line is a comment and is ignored. A `#` must be preceded by whitespace or start the line, so values containing `#` (like a URL fragment) are not split.

### Utility file keys

The special keys are reserved. Every other `key:value` line is an **environment key** — it sets an environment variable for the launched process (see Environment variables below).

| Key               | Required | Meaning                                                                                  |
| ---               | ---      | ---                                                                                      |
| `command`         | yes      | Executable path or name.                                                                 |
| `args`            | no       | Arguments to the command. May contain `{{placeholder}}` tokens filled from `input` keys. |
| `cwd`             | no       | Working directory.                                                                       |
| `slot`            | no       | Default slot key (`0–9`, `a–z`); auto-assigned on conflict, unique within the host window. |
| `input`           | no       | Repeatable; declares a user-input argument prompted at create time (see below).          |
| `use-process-env` | no       | If set, environment variables defined in the file are overridden by the calling process's environment when present there. See below. |

### Environment variables

Any `key:value` line that is not a special key is an environment variable. The key is the variable name; the value is its value. One variable per line, no `env` prefix, no comma separation:

```
PGPASSWORD: secret
FOO: bar
```

A value may contain any character, including `,` and `=`. This replaces the old comma-separated `KEY=VALUE,KEY=VALUE` form, which had an escaping problem that no longer exists.

At launch, the spawned process inherits the calling process's environment, then the file's environment keys are applied on top (so file values win over inherited). The `use-process-env` key changes that order for keys that also exist in the calling environment:

- `use-process-env: yes` — after applying the file's values, for each environment key that **also exists in the calling process's environment**, override the file value with the process value. The file provides defaults; the live environment wins for variables the user has set.

This lets a utility define its own defaults (`PGUSER: postgres`) while still picking up the user's live settings when present. Without `use-process-env`, the file's values always win. Environment values are static data — they do not contain `{{placeholder}}` tokens.

### The `input` key — user-input arguments

Some utilities need an argument the user must supply at create time — a location for a weather report, a file path for a log tail, a query for a database console. The `input` key declares these; `args`, `cwd`, and `command` reference them with `{{name}}` placeholders.

`input` is repeatable. Each line declares one placeholder:

```
input: location
input: unit
```

A weather utility that needs a location:

```
command: curl
args: "-s wttr.in/{{location}}?format={{unit}}"
input: location
input: unit
```

At create time (see Borrowing → Modes), tmux-borrow prompts for every `input` value in declaration order before any tmux mutation, then substitutes the answers into every `{{name}}` token in `args`, `cwd`, and `command`. Environment values are static and are never substituted. If standard input is not a TTY (non-interactive mode, e.g. inside a script or a `run-shell` call without a popup), the command fails with the names of the missing inputs rather than hanging on a prompt. `tum borrow` (which reuses an existing instance) never prompts — inputs are collected only when a new instance is created.

Secret values are supplied interactively or via a secret provider, never stored in definition files, layouts, or logs. Secret prompts read without echoing, like `read -s`.

### Safe argv

Arguments are stored and launched as an ordered array, so argument boundaries are preserved. No `eval`, no `sh -c` unless the user explicitly selects a shell as the executable. The parser treats any unrecognized key as an environment variable (see Environment variables); a key that is neither a special key nor a plausible variable name (empty, or containing characters invalid in an environment variable name) is reported as an error rather than silently ignored.

### Layout file keys

| Key         | Required | Meaning                                                      |
| ---         | ---      | ---                                                          |
| `layout_id` | no       | Layout id stamped on member panes. Defaults to the filename. |
| `focus`     | no       | Which member gets focus when the layout is borrowed. The value is a member name, or `host` to focus the host pane. Defaults to `host`. |

Member entries are not a `members:` key — see the DSL below.

### Layout DSL

A layout file is flat `key:value`, like a utility file — no `members:` wrapper, no indentation, no hierarchy. Every line is a top-level `key:value` entry parsed by the same single `while IFS=: read` loop. Two keys are special:

- `layout_id` — optional; the layout id stamped on member panes (defaults to the filename).
- `focus` — optional; which member gets focus when the layout is borrowed. The value is a member name or `host`; defaults to `host`. `host` is the default because borrowing a layout leaves you on the host pane anyway (the members attach beside it), so `focus` only matters when you name a member to steal focus to it.

Every other key is a **member entry**. The key is the member name (it must match a utility definition filename); the value is its placement:

```
<member-name>: anchor=<host|member-name>, side=<right|left|top|bottom>, size=<N%|Nc>
```

A complete layout file:

```
layout_id: dev
focus: editor          # editor gets focus when the layout is borrowed
editor: anchor=host, side=right, size=60%
term: anchor=host, side=bottom, size=20%
logs: anchor=term, side=bottom, size=30%
```

- `anchor` defaults to `host`. A member may anchor to another member, allowing two panes on the same side of the host (for example, editor right of host, logs below editor).
- `side` is required.
- `size` is a percentage of the anchor or a cell count; optional.

---

## Borrowing

Borrow is the primary action: attach a utility or layout beside the current host pane, creating it first if it does not exist.

### Pool and owned utilities

There are two kinds of instance, decided by which command creates them:

- **Pool utilities** are created by `tum borrow` (its create branch). They have no `home` host. Any host can borrow, hide, and re-borrow them. This is the shared-monitor case: one `htop` in the pool, borrowed into any window.
- **Owned utilities** are created by `tum new`. They carry `home` = the creating pane. Flip-flop (show after hide) returns an owned utility **only** to its home pane. Another host cannot take it by name; to move it, that host must pick it explicitly from the chooser (no-name `tum borrow`), which re-homes it. This is the project-file-manager case: a `ranger` that belongs to one window.

Both kinds can be created multiple times. Hiding an owned utility parks it in the hidden session — it stays owned, and the home pane can flip-flop it back at any time. Other hosts cannot re-borrow a hidden owned utility by name; to move it elsewhere they must pick it explicitly from the chooser, which re-homes it.

### Modes

| Mode          | Command               | Behavior                                                                                                                 |
| ---           | ---                   | ---                                                                                                                      |
| Default       | borrow <util or layout> | Borrow hidden instance bound to this host; else existing hidden pool instance (chooser if several); else create a pool instance and borrow it. |
| New           | new <util or layout>  | Always create a fresh owned instance (home = current pane), then borrow it. Sibling of borrow; skips the reuse-hidden branch. |
| No name       | borrow                | Chooser over all utilities and layouts. Uninstantiated picks create and borrow; instantiated picks borrow that instance. |
| New, no name  | new                   | Chooser over all utilities and layouts (same list as no-name borrow). Every pick creates a fresh owned instance, whether or not one already exists. |

Layouts follow the same pattern. `new` on a layout creates fresh owned member instances.

### Resolution order (default mode)

1. An instance already bound to this host (`host` equals the current pane id) — borrow it.
2. Else, hidden instances of this utility exist — borrow one (chooser if several). Pool instances are always available; owned instances are available only to their home host (see Stealing below). An orphan — whose `host` points at a dead pane — counts as hidden here; re-borrowing it clears the dead binding and sets the new host.
3. Else, create a pool instance and borrow it.

### Host binding

On borrow, the borrowed pane's state gets `host` = the current pane id. On hide or push, `host` is cleared.

### Stealing — decision table

"Stealing" is borrowing an instance that is currently shown and bound to another host. The rule depends on whether the instance is pool or owned, and on who is asking. (This table is a proposal to confirm; adjust the cells as you see fit.)

| Instance kind | Instance state                | Borrower is its owning/holding host | Borrower is a different host                          |
| ---           | ---                           | ---                                  | ---                                                   |
| Pool          | hidden (no holder)            | n/a (no holder when hidden)          | borrow it (chooser if several)                        |
| Pool          | shown (bound to a host)       | n/a (already yours)                  | **denied** — create a new pool instance instead       |
| Owned         | hidden (owned by home)        | borrow it (re-show; flip-flop returns here) | **denied** — create a new one, or pick another  |
| Owned         | shown (bound to its home)     | n/a (already yours)                  | **denied** — pick it explicitly via chooser to re-home |

"Owning/holding host" means: for a pool instance, the host it is currently shown to (its `host` field — there is none when hidden); for an owned instance, its `home` host, whether the instance is shown or hidden. The principle throughout: never silently take a pane another host is currently looking at. Pool instances are shared only when idle (hidden); owned instances are shared only when the new host asks for them explicitly by name from the chooser, which re-homes them.

---

## Flip-flop (hide / show)

Flip-flop toggles a borrowed thing between shown and hidden. It is generic — it does not name a utility, it acts on a slot. The CLI command is `tum flip`: `tum flip <slot>` toggles by slot; `tum flip` (no slot) is context-aware.

### Slot keys

Every borrowed thing — a utility instance, a layout group, or each member of a borrowed layout — gets a slot key from the range `0–9` or `a–z`, declared in its definition or auto-assigned on conflict. Slot keys are **unique within a host window**: no two borrowed things attached to the same window share a slot, so `<prefix> H <slot>` from that window always resolves to exactly one target. One slot is one flip-flop target.

A layout's slot toggles **all** its members as a group — a group hide hides every member (including any that were individually shown); a group show shows every member (including any that were individually hidden). A member's own slot toggles just that member. So an individually-hidden member is brought back by a group show, and re-hidden by a group hide.

### Shortcuts

| Action           | Shortcut          | Behavior                                                                                              |
| ---              | ---               | ---                                                                                                   |
| Toggle by slot   | `<prefix> H <slot>` | Hide if shown, show if hidden. A layout slot toggles all members together.                          |
| Toggle (context) | `<prefix> H`      | From a focused borrowed pane: toggle just that pane. From a host with one borrowed thing: toggle it. From a host with several: chooser. |

Flip-flop uses the same target resolver as `close` and `push`-from-host (see Target resolution below): focused borrowed pane → host's single borrowed thing → chooser when the host has several. An owned utility flipped back from hidden returns only to its home pane; a flip from another pane does nothing to it.

- Hiding a layout member parks it in the hidden session but keeps its `lay` field; re-showing the layout brings it back.
- Geometry is captured at hide and push (`geom`) and restored at show and pop.

---

## Hide and close

Two distinct actions with different shortcuts. Hide is non-destructive and reached through flip-flop (`tum flip`, above); close is destructive and is its own command, `tum close` — a context-aware `kill-pane` (see below). When a pane is closed, it is gone and tmux-borrow does nothing further with it; there is no exit-policy hook.

| Action        | What it does                                                              | State after                                         |
| ---           | ---                                                                       | ---                                                 |
| Hide (return) | `move-pane` to the hidden session; clear `host`; keep `lay` and `home`.   | Pane alive, parked, still a layout member, still owned if owned. |
| Close         | `kill-pane`.                                                              | Pane and its state gone. No cleanup.                |

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

### Target resolution (shared)

`close`, `flip`, and `push`-from-host all answer the same question: *which borrowed pane does the user mean right now?* The resolution is identical, so it lives in one internal helper — `tum-target` (a `tum-state` function, not a user command):

1. Is the focused pane itself borrowed? → act on it.
2. Is the focused pane a host with exactly one borrowed thing? → act on that.
3. Is it a host with several? → open the chooser.
4. None of the above → nothing to do, or error.

The chooser call lives inside `tum-target`, so the chooser is an internal decision — no command carries an `--interactive` flag. `borrow` keeps its own resolver (host-bound → hidden → create) because it can create, which the others cannot; its "pick among several hidden instances" step calls the same chooser.

---

## Push and pop

Push/pop is a separate command family — not bridged to layouts or any other command.

| Action | Command    | Behavior                                                                                                                 |
| ---    | ---        | ---                                                                                                                      |
| Push   | push      | Detach the focused borrowed pane onto a LIFO stack. Records geometry and push-seq; clears `host`. Pushed pane has no host. |
| Pop    | pop       | Attach the highest-`push` pane to the current host at its recorded geometry. Consumes it from the stack.                |

- The stack is `list-panes -a` filtered by panes whose state has a `push` field, sorted by `push` value descending. Non-contiguous sequence numbers are fine — panes may be closed between pushes.
- Push works from the focused borrowed pane, or from the host via `tum-target`: a host with one borrowed thing pushes that thing; a host with several opens the chooser.
- Pop attaches at the geometry recorded at push time.
- A user can compose a working set by pushing several utilities from anywhere, then popping them one by one into a host.
- Push/pop is independent of the pool/owned distinction. A pushed pane is just a stashed pane on the LIFO stack; `home` is untouched, and pop attaches to whoever pops. Flip-flop (which is governed by `home`) does not apply to a pushed pane — a pushed pane has no host and is not reachable by `tum flip`; bring it back with `tum pop`.

---

## Import

Adopt an existing tmux pane as a utility.

| Flavour   | Command        | Behavior                                                                                                                                                                         |
| ---       | ---            | ---                                                                                                                                                                              |
| Anonymous | import         | Make the current pane a temporary utility. No file written. `src=imported-anon`, `util` set to an auto-generated name (`import-<pane-id>`) so the chooser can list it. Gone when closed or when the server dies. |
| Named     | import <name>  | Capture command, args, cwd, env (max fidelity, from `/proc/$pid/`) and write a `<name>.util` file. `src=imported-named`, `util=<name>`. Editable; a normal utility. |

- Anonymous import is borrowable, hideable, and closeable like any utility, but is not saved.
- Named import captures as much as possible; the resulting definition file is meant to be hand-edited to refine.

---

## Layouts

- A layout is a named group of utilities. Borrowing a layout borrows all its members into the host window at their declared positions.
- `tum borrow <layout>` (default mode): borrow an existing hidden group bound to this host if any; else an existing hidden group (chooser if several); else create one.
- `tum new <layout>`: always create fresh member instances.
- Members may anchor to the host or to another member, allowing arbitrary trees on one side of the host.
- Each member gets its own slot for individual flip-flop; the layout group gets a slot for group flip-flop.
- Hiding a member keeps `lay`; a group show (the layout slot) brings it back. A group hide hides every member; a group show shows every member, regardless of each member's individual shown/hidden state.
- Closing a member removes it from the group; the layout id on survivors is unchanged. There is no layout instance to repair.

### Borrowing a layout (restore rules)

- Resolve all member definitions, missing `input` arguments, and conflicts before changing tmux.
- Add member panes incrementally beside the host and beside anchoring members. Never apply a whole-window `select-layout` to the host window if that would resize ordinary panes.
- If a member utility is already borrowed elsewhere, report the conflict rather than silently stealing it.
- Collect every required `input` argument before the first `join-pane`; a cancelled prompt leaves tmux state unchanged.

---

## Chooser

When a command must choose among several candidates, it routes the choice through an external chooser script via a defined API. The chooser is implicit — there is no `--interactive` flag; the decision to invoke it is internal to each command.

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
| Utility  | `util`                                                         |
| Layout   | `lay`                                                          |
| Host     | `host` (session:pane, or `hidden`, `host gone`, `pushed`)     |
| Home     | `home` (the owning pane, or `pool`)                            |
| Slot     | `slot`                                                         |
| Geometry | `geom`                                                         |
| State    | shown, hidden, pushed, or orphan                               |

- Global view: any session can borrow; `tum ls` shows where every instance lives and what it is bound to.

---

## Orphan handling

Lazy and manual, tmuxake-style. No proactive hooks on pane death.

| Condition                | Detection                                     | Action                                                                               |
| ---                      | ---                                           | ---                                                                                  |
| Host dead, utility alive | `host` pane id is not in `list-panes -a`      | Leave binding intact; mark `!`; show "host gone". User hides or re-borrows to clear. |
| Utility dead (full-dead) | Pane is gone from `list-panes -a`             | Nothing to do — state died with the pane. Automatic.                                 |

- `tum check` lists orphans for the user to act on.
- No auto-return. Detection is not a hide action; the binding stays until the user decides.

---

## Command summary

Every `tum` command, with its arguments. Behavior is defined in the sections above; this table is the index.

| Command       | Arguments                   | Behavior                                                                                                                              |
| ---           | ---                         | ---                                                                                                                                   |
| borrow        | `[<util or layout>]`        | Attach beside the current host pane; create first if needed. Reuses a hidden instance bound to this host, else a hidden pool instance, else creates. No-name opens the chooser over all. |
| new           | `[<util or layout>]`        | Always create a fresh owned instance (home = current pane) and borrow it. Sibling of borrow; skips the reuse-hidden branch. No-name opens the chooser over all; every pick creates a fresh owned instance. |
| flip          | `[<slot>]`                  | Toggle by slot, or (no slot) the focused pane — or the host's single borrowed thing, or the chooser for a host with several. Context-aware. |
| close         | (none — context-aware)      | `kill-pane` the focused borrowed pane, or the host's single borrowed thing, or chooser-pick among several.                            |
| push          | (none — context-aware)      | Detach the focused borrowed pane, or the host's single borrowed thing, or chooser-pick among several, onto the LIFO stack.            |
| pop           | (none)                      | Attach the top of the stack to the current host.                                                                                      |
| import        | `[<name>]`                  | Adopt the current pane as a utility — anonymous (no name) or named (writes `<name>.util`).                                            |
| ls            | (none)                      | List all utility panes across all sessions.                                                                                           |
| check         | (none)                      | List orphans (host dead, utility alive).                                                                                              |
| status        | `[<pane_id>]`               | Emit the glyph string for a pane (for the tmux status bar; tmux interpolates `#{pane_id}`).                                           |
| prompt        | (none)                      | Emit the PS1 glyph snippet for the shell prompt.                                                                                      |
| popup         | (none)                      | Open the full interactive menu (every command reachable).                                                                             |
| cheatsheet    | (none)                      | Open a popup listing every key binding.                                                                                               |

`tum popup` and `tum cheatsheet` are conveniences over the commands above; the keymap document defines the bindings they support.

### External scripts (not `tum` subcommands)

| Script        | Arguments                   | Behavior                                  |
| ---           | ---                         | ---                                       |
| `tum-chooser` | `<prompt> <items> <out>`    | The external chooser; fixed contract (see Chooser). |

---

## Help and manpages

Every `tum` command is self-documenting from one source of truth, so help text and the manpages can never drift.

- **Short help.** Every `tum <cmd>` accepts `-h`/`--help` and prints a short usage (the SYNOPSIS and EXAMPLES sections extracted from its manpage source). `tum` with no arguments, or `tum --help`, lists every subcommand with a one-line summary. The extraction is done by `tum_help <cmd>` reading `man/tum-<cmd>.1.md`; if the markdown is absent (a bare checkout before `make man`), a minimal hardcoded fallback is printed.
- **Manpage per command.** `man/` holds markdown sources: `tum.1.md` (overview + subcommand index), one `tum-<cmd>.1.md` per subcommand, `tum-defs.5.md` (the `.util`/`.layout` file format), and `tum-keymap.5.md` (the full keymap reference). Every page has NAME, SYNOPSIS, DESCRIPTION, OPTIONS, EXAMPLES (at least two real invocations), and SEE ALSO.
- **Generation.** `make man` renders `man/*.md` to `man/*.1`/`*.5` with pandoc (`pandoc -s -t man`); if pandoc is absent, a bundled `scripts/md2man.awk` handles the subset our sources use (headings, lists, fenced code). The generated roff files are gitignored; the markdown is canonical.
- **Install.** `make install` copies `bin/tum` to `$(BINDIR)`, the `scripts/` helpers to their directories, and every generated `man/*.1`/`*.5` to `$(MANDIR)`.

---

## Implementation constraints

- **Single file, one dispatcher.** All runtime code lives in `bin/tum`: every command is a small bash function (`cmd_borrow`, `cmd_new`, …) grouped with its helpers, and a `case` dispatcher at the bottom routes `tum <cmd> …` to the right function. A function that grows past ~40 lines is a signal to factor helpers out, not to split the file. The only code outside `bin/tum` is `scripts/tum-chooser` (an external fzf wrapper invoked by contract) and the static `scripts/tum-bindings.conf`.
- Bash preferred; Perl acceptable for short helpers. No Python in runtime code.
- No sqlite, no external database. Dynamic state is in the pane title (Alternative A, chosen by the viability test); static config is in `@tum-*` options.
- The chooser is an external script; fzf is one implementation, not a dependency of the core. The core works without any chooser installed (commands that need a chooser fall back to erroring or to a numbered list).
- All tmux interaction goes through one `tum-tmux` function group (in `bin/tum`) wrapping `new-session`, `new-window`, `split-window`, `join-pane`, `move-pane`, `move-window`, `select-pane -T`, and the rest. The rest of the code never calls `tmux` directly. tmux-version quirks, quoting, and pane-id verification live in one place.
- All state read/write goes through one `tum-state` function group that parses and emits the `tum:` field string, so the encoding rules — and the store (the pane title, with the `@tum-state` pane-scope option as an isolated fallback) — are implemented once.
- A shared `tum-target` resolver (in `tum-state`) answers "which borrowed pane does the user mean?" for `close`, `flip`, and `push`-from-host: focused borrowed pane, else the host's single borrowed thing, else the chooser. The chooser is invoked inside it, so no command carries an `--interactive` flag.
- Before borrow, the `command` path is checked to exist and be executable, so a bad definition fails with a clear message instead of launching a pane that dies at once.
- Bash completion completes commands, utility names, and layout names.
- Integration tests run against a private tmux server socket (`tmux -L tum-test -f /dev/null`), never the user's default server.
- tmux ≥ 3.2 is required. `display-popup` (the chooser/prompt overlay) needs tmux 3.2 and is the binding constraint. State the floor in the README.

---

## Companion documents

- `docs/implementation-roadmap.md` — the chronological build plan (phases, steps, Make targets) that implements this spec.
- `docs/design-rationale.md` — the *why* behind the decisions above: design lineage from tmuxake, a related-work survey, component-reuse choices, and the command-surface rationale.
- `man/` — the manpage sources (rendered by `make man`): `tum`(1), one `tum-<cmd>`(1) per subcommand, `tum-defs`(5), `tum-keymap`(5).
