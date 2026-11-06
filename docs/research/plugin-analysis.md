# Related projects and plugin analysis

This is an architectural comparison, not a dependency recommendation. Use native tmux commands through a small adapter. Do not inherit another project's assumptions without reviewing its current source, license, dependencies, and maintenance status.

| Project              | Useful capability                     | Gap                                              | Suggested use                    |
|----------------------|---------------------------------------|--------------------------------------------------|----------------------------------|
| tmuxake              | Utility/side-pane management ideas    | User reports one-extra-pane limitation           | Inspect selected ideas/code only |
| tmux-sessionist      | Pane/window movement between sessions | No registry, instance model, prompts, or layouts | Study command patterns           |
| tmux-resurrect       | Save/restore sessions, windows, panes | Broad tmux state, not borrowed-only resources    | Persistence reference only       |
| tmux-continuum       | Periodic resurrect saves              | Not a utility manager                            | Not required                     |
| fzf-pane-switch.tmux | fzf pane selection                    | Selection only, no lifecycle                     | Optional UI reference            |
| tmux-fzf-jump        | fzf navigation across tmux objects    | Navigation, not ownership/lifecycle              | Optional UI reference            |

## tmuxake

https://github.com/nkh/tmuxake

Conceptually close, but the user explicitly says it handles only one extra pane and must not be the foundation. Treat it as a source of ideas; inspect individual code only where license and quality permit. Do not inherit its core model or limitations.

## tmux-sessionist

https://github.com/tmux-plugins/tmux-sessionist

Useful for practical pane/window movement patterns. It does not provide definitions, stable instance identity, argument collection, borrowed-only layouts, or crash reconciliation.

## tmux-resurrect and continuum

https://github.com/tmux-plugins/tmux-resurrect
https://github.com/tmux-plugins/tmux-continuum

These address broad session persistence. The manager's layouts must contain only its own panes and must not overwrite ordinary user panes. Learn from serialization/recovery patterns, but do not require either plugin.

## fzf selectors

https://github.com/Kristijan/fzf-pane-switch.tmux
https://github.com/cengebretson/tmux-fzf-jump

Useful references for listing tmux objects and fzf interaction. They do not solve utility ownership or lifecycle. Keep fzf optional.

## Conclusion and verification

Use native `join-pane` and `move-window` through the manager's adapter. Implement registry, state, prompts, layout planning, and recovery specifically for this project. No listed project is a runtime dependency. Before copying code or asserting current versions/licenses/maintenance, inspect the repositories directly; this document makes no such current-status claims.
