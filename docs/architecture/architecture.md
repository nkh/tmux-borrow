# Architecture

## 1. Purpose and boundary

The manager adds a registry, instance tracking, borrowing/returning, argument prompts, layouts, and management interfaces.

tmux remains responsible for panes, windows, sessions, terminal rendering, key bindings, and hosting processes. The manager is not a second terminal multiplexer.

## 2. Operating model

An instance is one process in one tmux pane. That pane belongs to exactly one window at a time. Pane borrowing moves it; it does not duplicate the process or display it in two windows. Window borrowing moves a complete managed window between sessions.

## 3. Definitions and instances

A definition contains executable, default argv, argument declarations, working directory, environment, instance policy, lifecycle hooks, and exit policy.

An instance contains a stable manager ID, definition ID, process/pane identity, home location, current location, state, and optional working-window association.

## 4. Shared and per-window

A `shared` instance may be borrowed by different working windows, but only one at a time. A `per_window` instance belongs to one stable manager record for a working tmux window. That record is not the window's display name. If the window is destroyed/recreated, explicitly reassign or create a new record.

## 5. Host association

When borrowed beside a host pane, record the host's tmux pane ID and stable working-window record. This is metadata only; tmux has no pane hierarchy. Guarantee following for manager-issued movement commands. Register relevant hooks and reconcile when the manager next runs. Arbitrary external tmux commands may temporarily break the association. If the host closes, mark the association orphaned and offer keep, return, or reattach; never kill the utility automatically.

## 6. Home location

Record logical home session/window. Use a manager-owned empty placeholder window while the utility is borrowed, so the return destination remains stable. The placeholder must be clearly marked and contain no user process. Recreate a deleted home session/window on return; do not substitute a same-named session.

## 7. Layouts

Save utility references, arrangement among managed panes, destination mode, and argument policy.

## 9. Management interface

Provide CLI for all operations, one tmux popup entry point, optional fzf selection, `$EDITOR` integration, readline fallback, and Bash completion. Popup actions call the same CLI commands; do not create a second command language. Keep key bindings minimal: one configurable binding to open the popup.

## 10. Process architecture

Split into config reader, argument collector, state-store adapter, tmux adapter, instance manager, layout planner, lifecycle runner, selector, and completion. Keep each module narrow. All tmux calls are checked and their results verified.

## 12. Security

Treat config and argv as data. Never `eval`. Hooks are executable-plus-argv declarations, not interpolated shell fragments. Do not persist secret arguments in layouts, database payloads, or logs. Restrict state/config permissions to the user.

## 13. Native tmux versus manager

| Capability                   | Native tmux            | Manager contribution                       |
| ---                          | ---                    | ---                                        |
| Create/split panes           | Yes                    | Choose target and track ownership          |
| Move pane between windows    | `join-pane`            | Record home, destination, host association |
| Move window between sessions | `move-window`          | Select managed window and track lifecycle  |
| Session/window navigation    | Yes                    | Search utilities and layouts               |
| Process persistence          | Process stays in pane  | Registry and return-to-home behavior       |
| Utility definitions          | No                     | Executable and argument model              |
| Multiple instances           | Manual                 | Stable instance IDs and selection          |
| Per-window copies            | Manual                 | Find/create instance for working window    |
| Argument prompts             | No                     | Required values and presets                |
| Borrowed-only layouts        | No                     | Save/restore managed panes only            |
| Layout cloning               | No                     | Reuse shared; create local instances       |
| Idle policy                  | No generic safe policy | Optional utility-specific hooks            |
| fzf selection                | External/plugin        | Integrated management selector             |

## 14. Explicit limitations

A pane cannot be shown in two windows. Host following is guaranteed only for manager-mediated movement in the first release. Arbitrary programs cannot be safely suspended generically. Layout geometry in a mixed window cannot be guaranteed pixel-identical without affecting ordinary panes.
