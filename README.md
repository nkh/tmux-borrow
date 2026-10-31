# tmux utility manager

A documentation-first project scaffold for managing long-running terminal utilities as movable tmux resources.

**Working project name:** `tmux-utility-manager`  
**Working command name:** `tum`  
Both names are provisional.

The project is not a replacement for tmux. It adds a small management layer for utility identity, home locations, borrowing/returning, argument handling, saved borrowed-only layouts, and interactive selection.

## Project principles

- Small, composable Unix-style programs; no monolithic controller.
- Bash-first implementation, with short Perl helpers where they materially simplify parsing or data handling.
- tmux remains responsible for panes, windows, sessions, splitting, sizing, focus, and terminal presentation.
- Registered utilities and ad hoc utilities are both first-class.
- Ad hoc does not mean disposable: an ad hoc utility can be assigned to a session and managed just like a registered utility.
- Interactive management is a core feature, not an optional convenience.
- Never overwrite, save, restore, or destroy ordinary working panes when saving or restoring a borrowed-only layout.
- No dependency on tmuxake. Its useful architectural ideas and isolated code may be studied, but its one-extra-pane model is not the design foundation.

## Documentation

- [Requirements](docs/requirements.md)
- [Architecture and component boundaries](docs/architecture.md)
- [User guide](docs/user-guide.md)
- [20 use cases](docs/use-cases.md)
- [tmux feature mapping](docs/tmux-feature-map.md)
- [Plugin analysis](docs/plugin-analysis.md)
- [Project plan and open decisions](docs/project-plan.md)

## Status

This is a requirements and design baseline, not an implementation. Command names and configuration syntax are illustrative until validated by a prototype.
