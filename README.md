# tmux-utility-manager

A design and implementation specification for managing long-running terminal utilities under tmux.

## Core model

A **definition** describes a utility; an **instance** is one running copy. Each instance has a managed home session/window and one live tmux pane.

Borrowing moves a pane. A pane exists in one tmux window at a time.

- Small, composable Unix-style programs.
- Bash-first implementation, with short Perl helpers where they materially simplify parsing or data handling.
- tmux remains responsible for panes, windows, sessions, splitting, sizing, focus, and terminal presentation.
- Registered utilities and ad hoc utilities are both first-class.
- Ad hoc does not mean disposable: an ad hoc utility can be assigned to a session and managed just like a registered utility.
- Interactive management is a core feature.
- Never overwrite, save, restore, or destroy ordinary working panes when saving or restoring a borrowed-only layout.

## Documents

- `requirements/`: behavior, lifecycle, layouts, arguments, terminology, use cases.
- `architecture/`: tmux model, ownership, process boundaries, failure recovery.
- `metadata/`: persistent schema, transactions, locking, migration.
- `commands/`: CLI and popup interaction contracts.
- `user-guide/`: user workflows.
- `development/`: staged plan, tests, AI implementation contract.
- `research/`: related projects and plugin analysis.
- `ideas/`: 200 optional improvements.

