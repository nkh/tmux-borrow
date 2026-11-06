# Getting started

This archive specifies the intended product; installation steps will be added with the first implementation release.

1. Install tmux, Bash, SQLite, and a supported TOML parser.
2. Optionally install fzf for fuzzy selection.
3. Run `tum doctor` to check dependencies and state permissions.
4. Run `tum define add --wizard` to register a utility.
5. Run `tum run NAME` to start it in its home window.
6. From a working window, run `tum borrow --fzf` to borrow it.
7. Run `tum return --fzf` to return it.

A definition is a recipe; an instance is a running process. Borrowing moves the existing pane. Layouts save managed utility panes only, not ordinary working panes.
