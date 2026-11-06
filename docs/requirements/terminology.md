# Terminology

| Term                | Meaning                                                            |
|---------------------|--------------------------------------------------------------------|
| Utility             | A kind of program, such as a file manager or log viewer            |
| Definition          | Saved configuration describing how to start a utility              |
| Instance            | One running process represented by one managed tmux pane           |
| Home session/window | Normal managed tmux location for an instance                       |
| Working window      | tmux window where the user is doing other work                     |
| Borrow              | Move an existing managed pane/window into a working location       |
| Return              | Move a borrowed pane/window back to its home                       |
| Host pane           | Pane beside which a utility is borrowed                            |
| Host association    | Manager metadata linking a borrowed pane to a host pane            |
| Shared instance     | One instance eligible for borrowing from different windows         |
| Per-window instance | Instance assigned to one stable working-window record              |
| Layout              | Recipe containing only managed utility panes and their arrangement |
| Clone layout        | Create a new layout without moving source resources                |
| Argument preset     | Named set of argument values for one utility                       |
| Ad-hoc utility      | Utility launched without a saved reusable definition               |
| Managed pane        | Pane whose process and location this manager tracks                |
| Ordinary pane       | Pane not owned or tracked by this manager                          |

