# tmux operating model

A tmux server contains sessions; sessions contain windows; windows contain panes. Runtime IDs such as `$N`, `@N`, and `%N` identify live objects but are not durable manager IDs and may change after restart/recreation.

Relevant commands include `new-session`, `new-window`, `split-window`, `join-pane`, `move-window`, `display-message`, `show-options`, and `set-option`. Use tmux commands rather than editing internal state, and verify every move by querying IDs afterwards.

Panes in a window are peers. Moving pane A does not automatically move pane B. A manager host association is a database relationship, not a native tmux parent-child link.

One pane exists in one window at a time. Showing the same process in two windows would require nested multiplexers or a terminal proxy; neither is in the initial design.

Keep a managed empty home placeholder while the utility pane is borrowed. Replace it when the pane returns. The placeholder must never contain a user process.
