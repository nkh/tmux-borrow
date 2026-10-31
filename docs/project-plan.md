# Project plan and open decisions

## Recommended implementation sequence

### Phase 0 — tmux behavior spike

Prove pane and window movement, home restoration, multi-source borrowing, pane styles, and popup behavior with shell scripts. No registry or UI framework yet.

### Phase 1 — identity and state

Implement stable instance IDs, session/socket identity, atomic metadata, inventory, stale-state detection, and duplicate visible session-name handling.

### Phase 2 — launch path

Implement registered definitions, ad hoc launch, argument-vector safety, config precedence, home-session assignment, window/shared scope, and lifecycle policy.

### Phase 3 — borrow/return

Implement borrowing of utility windows and panes, arbitrary pane borrowing, multi-pane layouts, split argument prompt/default, return-one, return-all, and termination.

### Phase 4 — interactive management

Implement popup entry point, fzf backend, tree inventory, action menu, home-session termination, and minimal key bindings. Add a basic key-reader fallback only if it is useful.

### Phase 5 — layouts and editing

Implement borrowed-only layout save/apply/replace, `$EDITOR` integration, fzf selection, Bash completion, and setup wizard.

### Phase 6 — hardening

Test recovery, multiple sockets, stale IDs, tmux version differences, argument injection, color restoration, partial failures, and documentation examples.

## Open decisions

1. **Project and CLI names:** `tmux-utility-manager` / `tum` are placeholders.
2. **Config format:** YAML is readable but introduces a parser dependency. TOML or shell-independent key/value format may be better. Avoid sourcing arbitrary config as shell code.
3. **Session identity:** tmux session IDs are stable only within a server lifetime. Decide how to reconcile them after server restart.
4. **Home session lifecycle:** Should an automatically created home session be kept alive when empty, and when should it be cleaned up?
5. **Ad hoc session policy:** Default auto assignment could use one shared tools session, one session per project, or one session per utility family. The wizard should offer a simple default.
6. **Window-scoped identity:** Determine how a project/user window is identified and how instances behave if that window is renamed, moved, or recreated.
7. **Argument semantics:** Confirm whether invocation args append to or replace definition defaults. Proposed default is append, with explicit replacement option.
8. **Borrowing arbitrary panes:** Define return behavior when the original source window/session disappears.
9. **Layout semantics:** Define how to preserve ordinary pane geometry when manager-owned borrowed panes are removed or replaced. tmux may necessarily resize surviving panes.
10. **Color mechanism:** Verify per-pane style support across the minimum supported tmux version and terminal.
11. **Selector implementation:** Start with fzf, but keep a CLI-action interface and avoid coupling the whole project to fzf.
12. **Minimum versions:** Set minimum tmux, Bash, and optional fzf versions after the behavior spike.
13. **Storage location:** Default to XDG state/data; allow an override. Avoid `/var` unless the user deliberately configures a shared installation and permissions.
14. **tmux plugin reuse:** Prefer native tmux commands. Any copied code requires license and maintenance review.

## Initial release acceptance criteria

- A utility definition can accept arguments.
- An ad hoc command can be launched with CLI overrides, inherited defaults, and manual/automatic session assignment.
- Utilities occupy full windows in home sessions.
- A utility can be borrowed as a full window or as a pane without restarting its process.
- An arbitrary pane from any session can be selected and borrowed.
- Multiple borrowed resources from multiple sessions can coexist.
- A split borrow can request an argument interactively or use an explicit/default value.
- A utility can be borrowed with a background color and have that style restored.
- A borrowed utility can be killed; home utilities can be listed and killed by CLI and selector.
- A saved layout contains only manager-owned borrowed resources.
- Config/layout files can be opened in `$EDITOR` without the user knowing their paths.
- Bash completion and a setup wizard exist.
- The code remains a set of small composable utilities.
