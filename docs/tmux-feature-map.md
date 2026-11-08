# Project functionality mapped to tmux

The manager must not recreate features tmux already provides. This table identifies what tmux supplies directly and what additional project work is required.

| Project capability    | functionality              | What tmux already does                    | Extra work required by this project?                                  |
| ---                   | ---                        | ---                                       | ---                                                                   |
| Create sessions       | `new-session`              | Creates sessions, detached or attached.   | policy for home-session assignment.                                   |
| Create windows        | `new-window`               | Creates windows within sessions.          | create a full-window utility instance .                               |
| Create panes          | `split-window`             | Splits a window and starts a command.     | borrow an existing running pane.                                      |
| Move pane             | `join-pane`, `move-pane`   | Moves an existing pane.                   | identify resource, ...                                                |
| Move a window         | `move-window`              | Moves an existing window.                 | home-session tracking.                                                |
| Switch                | client, window, pane       | Native navigation and focus.              |                                                                       |
| Resize panes          | `resize-pane`              | Resizes panes.                            |                                                                       |
| Zoom pane             | `resize-pane -Z`           | Toggles zoom.                             |                                                                       |
| Pane layouts          | select, next, previous     | Applies built-in layouts to a window.     |                                                                       |
| Kill                  | pane, window, session      | Terminates tmux resources.                | map instance IDs, confirm targets.                                    |
| Pane colors           | style options              | pane-specific styling.                    | configured/per-instance borrowed color.                               |
| Popup UI              | `display-popup`            | Opens a popup running a command.          | project-specific management UI                                        |
| Key bindings          | bind, unbind               | Configures shortcuts.                     | install a small, configurable set of bindings.                        |
| List                  | sessions, windows, panes   | Lists tmux topology.                      | merge tmux inventory with manager-owned identity.                     |
| Environment           | -c option                  | Sets working directories and environment. | scope-aware launch defaults.                                          |
| Fuzzy selection       | Not a tmux feature.        | Provides popup container.                 | fzf/key-reader UI.                                                    |
| CLI completion        | not tmux core.             | None for this project.                    | Bash completion.                                                      |
| Edit                  | `source-file`.             | Can reload tmux configuration.            | open project config/layouts.                                          |
| Setup wizard          | None.                      | None.                                     |                                                                       |
| Register              | None.                      | panes/windows.                            | registry, argument schema.                                            |
| Ad hoc utilities      | tmux launches commands.    | Runs commands in sessions/windows/panes.  | auto/manual home assignment, instance IDs ...                         |
| shared utility scope  | Sessions/windows manually. | containers only.                          | scope identity and instance reuse/creation rules.                     |
| Terminate by identity | tmux kills by tmux target. | Kills live tmux objects.                  | resolve stable instance ID and display meaningful target information. |

## Design rule

If the tmux command already performs the operation, call it. The project adds only the identity, policy, metadata, selection, argument resolution, and safety layer needed to make that operation utility-aware.
