# Borrowing and returning

Run `tum borrow --fzf` or use the popup. The manager moves the existing pane into the working window; it does not restart the utility. If required values are missing, it prompts before moving.

When borrowing beside a pane, the manager records that pane as the host. This is not a tmux parent/child relationship. Manager-issued movement preserves the association. External movement may require reconciliation. If the host disappears, the utility remains running and the manager offers repair choices.

Use fzf multi-select for batch borrowing. All arguments and conflicts are resolved before the first move. Use window mode when the complete managed window should move. Return with `tum return --fzf`; the manager restores home location and temporary appearance.
