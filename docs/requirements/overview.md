# Product overview

## Problem and goals

Power users keep file managers, log followers, REPLs, database consoles, monitors, debuggers, and build watchers running in tmux. They want to move an already-running utility into a working window and later return it without restarting it.

The manager provides a utility registry, instance tracking, home locations, borrowing/returning, argument prompting, layouts, cloning, fzf selection, a popup, configuration editing, and completion.

## Goals

- Register definitions and launch registered or ad-hoc utilities.
- Support multiple instances of one definition.
- Keep instances in managed home sessions/windows when not borrowed.
- Borrow one pane into the current window or move a whole managed window.
- Associate a borrowed pane with a host pane for manager-mediated moves.
- Borrow several utilities or arrange them in separate windows.
- Save/restore/clone layouts containing only managed utility panes.
- Prompt for missing arguments and support named argument presets.
- Keep the implementation small and split into independent commands.

## Non-goals

- Reimplement tmux navigation, zoom, resizing, splitting, or session management.
- Display one native tmux pane in multiple windows simultaneously.
- General-purpose process checkpointing or migration.
- Generic suspension of arbitrary applications.
- Managing ordinary user panes as utility resources.
- Depending on tmuxake as the implementation foundation.

## Principles

Explicit ownership; predictable moves; native tmux for native tmux features; safe defaults; recoverability; inspectable state; no shell re-parsing of arguments.
