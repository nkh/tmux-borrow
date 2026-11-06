# Project functionality mapped to tmux

The manager must not recreate features tmux already provides. This table identifies what tmux supplies directly and what additional project work is required.

| Project capability | functionality            | What tmux already does                    | Extra work required by this project?                   |
|--------------------|--------------------------|-------------------------------------------|--------------------------------------------------------|
| Create sessions    | `new-session`            | Creates sessions, detached or attached.   | Yes: policy for home-session assignment.               |
| Create windows     | `new-window`             | Creates windows within sessions.          | Yes: create a full-window utility instance .           |
| Create panes       | `split-window`           | Splits a window and starts a command.     | Yes: borrow an existing running pane.                  |
| Move pane          | `join-pane`, `move-pane` | Moves an existing pane.                   | Yes: identify resource, ...                            |
| Move a window      | `move-window`            | Moves an existing window.                 | Yes: home-session tracking.                            |
| Switch             | client, window, pane     | Native navigation and focus.              | No.                                                    |
| Resize panes       | `resize-pane`            | Resizes panes.                            | No.                                                    |
| Zoom pane          | `resize-pane -Z`         | Toggles zoom.                             | No.                                                    |
| Pane layouts       | select, next, previous   | Applies built-in layouts to a window.     | Yes.                                                   |
| Kill               | pane, window, session    | Terminates tmux resources.                | Yes: map instance IDs, confirm targets.                |
| Pane colors        | style options            | pane-specific styling.                    | Yes: configured/per-instance borrowed color.           |
| Popup UI           | `display-popup`          | Opens a popup running a command.          | Yes: project-specific management UI                    |
| Key bindings       | bind, unbind             | Configures shortcuts.                     | Yes: install a small, configurable set of bindings.    |
| List               | sessions, windows, panes | Lists tmux topology.                      | Yes: merge tmux inventory with manager-owned identity. |
| Environment        | -c option                | Sets working directories and environment. | Yes: scope-aware launch defaults.                      |
| Fuzzy selection    | Not a tmux feature.      | Provides popup container.                 | Yes: fzf/key-reader UI.                                |
| CLI completion     | not tmux core.           | None for this project.                    | Yes: Bash completion.                                  |
| Edit               | `source-file`.           | Can reload tmux configuration.            | Yes: open project config/layouts.                      |
| Setup wizard       | None.                    | None.                                     | Yes.                                                   |
| Register           | None.                    | panes/windows.                            | Yes: registry, argument schema.                        |
| Ad hoc managed utilities | tmux can launch arbitrary commands. | Runs arbitrary commands in sessions/windows/panes. | Yes: auto/manual home assignment, instance IDs, metadata, later selection and return. |
| Per-window vs shared utility scope | Sessions/windows can be created manually. | Provides containers but no utility reuse policy. | Yes: scope identity and instance reuse/creation rules. |
| Terminate by utility identity | tmux kills pane/window/session by tmux target. | Kills live tmux objects. | Yes: resolve stable instance ID and display meaningful target information. |

## Design rule

If the tmux command already performs the operation, call it. The project adds only the identity, policy, metadata, selection, argument resolution, and safety layer needed to make that operation utility-aware.
