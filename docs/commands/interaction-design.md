# Interactive management design

Use one popup entry point (`tum popup`) with a compact action list: borrow, return, manage/list instances, start utility, restore/save layout, edit config, diagnostics. Each action delegates to the same CLI command used in scripts.

fzf is the primary searchable selector when installed. Display definition, instance ID suffix, state, and current/home location. Enable multi-select only for batch-safe actions. Without fzf, provide a numbered readline selector. The core CLI must work without fzf.

Keep tmux key bindings minimal: one configurable binding opens the popup. Do not bind every action separately. Collect all required argument prompts before any batch move or layout restore. Cancelling a prompt must leave tmux state unchanged.
