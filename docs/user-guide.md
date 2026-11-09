# tmux-borrow — user guide

This guide describes the intended user experience. The CLI syntax is provisional and will be finalized after a working prototype.

## The basic idea

A utility runs in a pane. You can bring that existing running pane into the window where you are working — the process keeps running, it is moved not restarted. When you are done, hide it out of the way; bring it back with the same key. Close it for good with another key. All state lives in tmux itself, so there is nothing to corrupt and nothing to reconcile after a crash.

This is useful for long-lived tools: file managers, log viewers, REPLs, database consoles, monitors, debuggers, `lazygit`. You can also group several utilities into a named layout, hand a utility off to another session with push/pop, and adopt any existing pane as a temporary utility with import.

tmux-borrow is a superset of tmuxake: the same hide/show/close flow, generalized to named utilities, layouts, multiple instances, and a pluggable chooser.

## First run

Put your utility and layout definitions in `~/.config/tum/` (or wherever `XDG_CONFIG_HOME` points). Each utility is one file (`<name>.util`), each layout is one file (`<name>.layout`), flat `key:value`. The filename is the name.

Open the config directory in `$EDITOR`:

```sh
tum config edit
```

## Define a utility

A utility file is flat `key:value`:

```
command: htop
tags: monitor
slot: 1
on_exit: wait
```

Only `command` is required. `args`, `cwd`, `env`, `tags`, `slot`, and `on_exit` are optional.

## Borrow a utility

Borrow attaches a utility beside the current pane, creating it first if it is not already running:

```sh
tum borrow htop
```

If a hidden `htop` instance is already bound to this pane, it comes back. If hidden instances exist but none are yours, the chooser picks one. If none exist, a new one is created and borrowed.

Three modes give you control:

```sh
tum borrow htop            # existing-or-create (default)
tum borrow --new htop      # always create a fresh instance
tum borrow --existing htop # only borrow an existing instance
```

Borrow with no name opens the chooser over everything:

```sh
tum borrow                 # chooser over all utilities and layouts
```

Borrow by tag:

```sh
tum borrow --tag monitor
```

## Hide and show (flip-flop)

Every borrowed thing gets a slot key — a single character, declared in its definition or auto-assigned. One key toggles it in and out:

```
<prefix> H 1    hide or show slot 1
<prefix> H 1    (again) show or hide slot 1
```

From a focused borrowed pane, `<prefix> H` with no slot toggles just that pane. The geometry is remembered: hide a pane that was 30% wide, show it, and it lands at 30% again.

## Close

Close is `kill-pane` — the pane and all its state are gone, nothing to clean up:

```
<prefix> <close key>
```

It is context-aware: if you are focused on a borrowed pane, it closes that pane. If you are on the host with one borrowed thing, it closes that. With several, the chooser picks. No confirmation; close is immediate.

## Borrow a layout

A layout groups several utilities. Define it in a `.layout` file:

```
layout_id: dev
members:
  editor: anchor=host, side=right, size=60%
  term:   anchor=host, side=bottom, size=20%
  logs:   anchor=term, side=bottom, size=30%
```

Members may anchor to the host or to another member — `logs` anchors below `term`, so both sit on the bottom while `editor` takes the right.

Borrow the whole group:

```sh
tum borrow dev
```

All members attach at their declared positions. The layout gets a slot (toggle all members together); each member gets its own slot (toggle individually). Close one member and the rest continue; the layout is just an id stamped on the panes, so there is nothing to repair.

## Push and pop

Push detaches a borrowed pane onto a stack — it has no host, it is just parked. Pop attaches the top of the stack to your current pane:

```sh
tum push     # from the focused borrowed pane
tum pop      # attaches the top of the stack here
```

The stack is LIFO, so push a few utilities from anywhere, then pop them one by one to assemble a working set. Each pane pops at the geometry it had when pushed. Push/pop is fully separate from layouts and borrowing — it does not interact with them.

## Import

Take any existing pane and make it a utility:

```sh
tum import              # anonymous: temporary, not saved
tum import prod-db      # named: captures command/args/cwd/env to a file
```

An anonymous import is borrowable, hideable, and closeable like any utility, but is not saved — close it and it is gone. A named import captures as much fidelity as possible (command, arguments, working directory, environment) and writes a `prod-db.util` file you can hand-edit to refine; thereafter it is a normal utility, available in any session.

## The chooser

Any command that needs you to pick something takes `--interactive`, which routes the choice through an external chooser script:

```
tum-chooser <prompt> <items_file> <output_file>
```

The script reads items from a file, writes the selection to a file, exits 0 on selection or non-zero on cancel. An fzf-based implementation ships as the default; any script following the contract is a drop-in replacement. The core works without a chooser — commands that need one fall back to erroring or a numbered list.

## Status glyphs

The tmux status bar (or your bash prompt) can show, at a glance, which panes are borrowed:

- `÷` on a host pane means it has utilities or layouts attached.
- `§` on a borrowed pane means it is a utility (with its name).
- `!` prefix means the host is dead and the utility is orphaned.

Both glyphs are configurable.

## List everything

```sh
tum ls        # all utility panes across all sessions
tum check     # list orphans (host dead, utility alive)
tum status    # glyph string for the current pane
```

`tum ls` shows each instance's utility, layout, host (or `hidden`/`host gone`/`pushed`), slot, geometry, and state. Any session can borrow from the shared pool, so this is the global view.

## What you can do

These are the workflows tmux-borrow is built for. Each maps to the features above.

- **Project file manager per window.** Borrow a `ranger` instance rooted in your project; hide it when you need the space; show it with the same key. Borrow `--new` for a second project.
- **Shared system monitor.** One `htop` instance lives in the hidden pool; borrow it into any window, hide it, bring it back — it never restarts.
- **Multiple log streams.** Borrow several `tail` instances into one debugging window; hide the ones you are not reading.
- **Ad hoc build log.** `tum import` an existing `tail -F build.log` pane; borrow it elsewhere; close it when done.
- **Database console on demand.** `tum import prod-db` captures a running `psql`; after a server restart, `tum borrow prod-db` recreates it from the saved definition.
- **Git UI across projects.** A shared `lazygit` borrowed into any window; a project-scoped `--new` instance for a specific repo.
- **Debugger and logs together.** Define a `debug` layout (debugger + two logs); `tum borrow debug` brings all three in at once; toggle the group with one slot.
- **Switch task context.** Push your current utilities onto the stack; pop them back when you return — no layout file needed.
- **Kill stale background tools.** `tum ls` finds them in any session; close from the list or the pane.
- **Recover after an interruption.** `tum check` lists orphans (host dead, utility alive); re-borrow to rebind, or close to clear. Full-dead panes are already gone — state died with them.
