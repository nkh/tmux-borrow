# tmux plugin analysis

Research snapshot: 2026-10-30. This is an architectural assessment, not a claim that any plugin should become a hard dependency. Plugin behavior and compatibility should be rechecked against the exact release selected during implementation.

## Executive recommendation

Do not build the project on a single existing plugin. Use tmux's native pane/window movement commands as the core execution layer, then selectively reuse ideas or optional integrations:

1. **tmux-sessionist** is the most directly relevant reference for moving marked panes/windows between sessions and joining panes into a current window.
2. **fzf-pane-switch.tmux** is a strong reference for a searchable, tree-shaped session/window/pane chooser and pane identity-aware refresh.
3. **tmux-fzf-jump** is a second useful selector reference, with context-sensitive actions and a broad management menu, but overlaps with fzf-pane-switch.
4. **tmux-resurrect** is useful for persistence/recovery techniques, but its whole-environment model is not suitable as the borrowed-only layout engine.
5. **tmux-continuum** is optional if automatic periodic tmux environment snapshots are desired, but it depends on resurrect and is not required for utility management.

No plugin examined provides the complete combination of utility definitions, ad hoc managed instances, home-session policy, cross-session borrowing, stable instance identity, borrowed-only layout persistence, CLI overrides, per-window/shared scope, and lifecycle management.

## 1. tmux-sessionist

Repository: https://github.com/tmux-plugins/tmux-sessionist

### Relevant behavior

The plugin supplies lightweight session manipulation commands. Its documented key bindings include:
- promote the current pane into a new session;
- promote the current window into a new session;
- join the currently marked pane into the current session/window;
- join horizontally, vertically, or full-screen.

### Fit

This is the closest conceptual match for the low-level “move an existing pane into my current context” operation. It demonstrates a small set of composable tmux commands rather than a large stateful application.

### What can be reused

- The workflow of marking a pane and joining it into the current window.
- The mapping between user intent (horizontal/vertical/full-screen) and tmux-native movement commands.
- Small command wrappers and key-binding conventions, subject to code/license review.

### What it does not solve

- No utility registry or registered definitions with arguments.
- No managed ad hoc instance model.
- No stable manager instance IDs.
- No home-session assignment or automatic session policy.
- No per-window/shared utility scope.
- No saved borrowed-only layouts.
- No manager-owned return metadata for many simultaneous borrowed resources.
- No lifecycle policy or utility-aware termination UI.
- No split argument prompt/default mechanism.

### Recommendation

Use it as a reference and possibly as an optional dependency only if the exact command behavior is useful. Prefer implementing the required movement calls directly in a tiny `tum-tmux` helper so the project controls error handling and metadata updates. Avoid depending on its key bindings because the project wants one main popup shortcut rather than many shortcuts.

Source: https://github.com/tmux-plugins/tmux-sessionist

## 2. fzf-pane-switch.tmux

Repository: https://github.com/Kristijan/fzf-pane-switch.tmux

### Relevant behavior

The plugin switches to panes in any tmux session using fzf. Its recent documented features include one-row, two-row, and tree layouts; session/window/pane rows; configurable display formats and colors; jump labels; preview; refresh; and identity-aware selection. The current release notes report fzf 0.71+ and tmux 3.3+ for the newer identity-tracking features.

### Fit

Strong reference for the project's management popup. The hierarchical session → window → pane view maps naturally to the requirement to borrow or terminate resources from any session, including panes that are not registered utilities.

### What can be reused

- Tree presentation of session/window/pane hierarchy.
- Refresh while preserving the current query and selected pane identity.
- Configurable row formats and preview.
- Searchable list generation based on tmux format output.
- Popup-oriented interaction patterns.

### What it does not solve

- It switches to panes; it does not implement the manager's borrow/return ownership model.
- It does not provide utility definitions, launch argument merging, ad hoc session assignment, scope rules, or saved borrowed-only layouts.
- It does not decide whether a selected pane is managed, returnable, or merely an arbitrary pane.
- It does not provide the required utility lifecycle behavior.

### Recommendation

This is the strongest candidate to study for the selector frontend. Either:
- call it as an optional “switch to pane” action, while implementing separate manager actions; or
- borrow its list/preview/tree interaction ideas and implement a smaller project-specific fzf frontend.

Do not fork it wholesale unless its extension points and license make that clearly cheaper than a small adapter. The project needs action-specific semantics (borrow, return, kill, inspect), not just switch.

Sources:
- https://github.com/Kristijan/fzf-pane-switch.tmux
- https://github.com/Kristijan/fzf-pane-switch.tmux/releases

## 3. tmux-fzf-jump

Repository: https://github.com/cengebretson/tmux-fzf-jump

### Relevant behavior

Provides fzf-based switching to sessions, windows, and panes in a hierarchy. The README documents context-sensitive actions including creation, renaming, detaching, killing, preview, and help. It documents fzf 0.53+ (with `--tmux`), tmux 3.4+, and Bash 3.2+.

### Fit

Useful reference for a command-control selector rather than a simple one-purpose picker. Its tree and action model resembles the desired management interface.

### What can be reused

- Tree inventory model.
- Action menu and key-help pattern.
- Preview and context-sensitive actions.
- The idea of one entry shortcut exposing several management operations.

### What it does not solve

- It is a navigation/management selector for tmux objects, not a utility lifecycle manager.
- It has no stable utility registry or instance/home relationship.
- It does not provide borrowed-only layout save/restore.
- Its kill action is tmux-object-oriented rather than utility-instance-oriented.
- It does not implement the project's launch config precedence or ad hoc utility management.

### Recommendation

Compare it with fzf-pane-switch during the UI prototype. Do not install both by default: they overlap substantially. Pick one as the initial reference or optional backend. A project-specific selector should call the same CLI commands used outside the UI.

Source: https://github.com/cengebretson/tmux-fzf-jump

## 4. tmux-resurrect

Repository: https://github.com/tmux-plugins/tmux-resurrect

### Relevant behavior

Saves and restores broad tmux environment state: sessions, windows, panes, ordering, working directories, layouts, focus, and a conservative set of running programs. It exposes save/restore key bindings and hooks before/after save and restore. It also has logic to avoid restoring panes that already exist.

### Fit

Useful reference for persistence, serialization, idempotence, hooks, and restore safety. However, its purpose is broad environment recovery, not saving a subset of manager-owned borrowed panes.

### What can be reused

- State-file serialization patterns.
- Idempotent restore concepts.
- Hook-based integration points.
- Recovery and stale-resource handling ideas.
- Tests and compatibility practices for tmux state restoration.

### What it does not solve

- Does not provide a borrowed-only layout abstraction.
- Its saved environment covers general tmux state, which is explicitly broader than this project's scope.
- Does not own utility definitions or ad hoc utility identities.
- Does not implement return-to-home semantics for moved utility resources.
- Restoring a full tmux environment risks touching ordinary panes, contrary to this project's strict isolation requirement.

### Recommendation

Do not use resurrect as the layout engine or as a required dependency. Study its serialization and recovery code for narrowly reusable techniques. If the user separately wants whole-environment restart recovery, document resurrect as an optional companion with clear separation: resurrect handles global tmux recovery; this project handles utility ownership and borrowed-only arrangements.

Sources:
- https://github.com/tmux-plugins/tmux-resurrect
- https://github.com/tmux-plugins/tmux-resurrect/blob/master/docs/hooks.md
- https://github.com/tmux-plugins/tmux-resurrect/blob/master/docs/restoring_previously_saved_environment.md

## 5. tmux-continuum

Repository: https://github.com/tmux-plugins/tmux-continuum

### Relevant behavior

Continuously saves the tmux environment at a configurable interval, can start tmux automatically, and can restore the saved environment when tmux starts. Its README documents a dependency on tmux-resurrect and Bash. Its periodic save mechanism uses the status line.

### Fit

Only relevant to whole-server/session persistence. It does not add utility-aware borrowing or layout semantics.

### Recommendation

Do not depend on it. It may be used alongside the project if the user already wants automatic whole-environment snapshots. Keep its save/restore domain separate from manager metadata and borrowed-only layouts.

Sources:
- https://github.com/tmux-plugins/tmux-continuum
- https://github.com/tmux-plugins/tmux-continuum/blob/master/docs/faq.md

## 6. Comparative matrix

| Plugin               | contribution                          | supports borrowing?    | registry/lifecycle? | Borrowed-only? | role                                |
| ---                  | ---                                   | ---:                   | ---:                | ---:           | ---                                 |
| tmux-sessionist      | Mark/join/move pane and window        | Yes, basic movement    | No                  | No             | Movement reference; optional helper |
| fzf-pane-switch.tmux | Tree selector, pane identity, preview | No; primarily switches | No                  | No             | Best selector reference             |
| tmux-fzf-jump        | Hierarchical fzf UI and actions       | No; primarily switches | No                  | No             | Alternative selector reference      |
| tmux-resurrect       | Broad persistence and recovery        | No                     | No                  | No             | Study serialization/recovery only   |
| tmux-continuum       | Periodic whole-environment saving     | No                     | No                  | No             | Optional companion only             |

## 7. Recommended integration strategy

### Core

Use tmux-native operations directly:
- `new-session`, `new-window`, `split-window`;
- `join-pane` / `move-pane`;
- `move-window`;
- `list-sessions`, `list-windows`, `list-panes`;
- `kill-pane`, `kill-window`, `kill-session`;
- `display-popup`;
- `select-layout` and pane style commands where supported.

The project should wrap these in small helpers that validate targets and update metadata. The wrapper is where project-specific value lives.

### Optional selector

Prototype `tum-select` against fzf. Study fzf-pane-switch for tree rendering and identity-preserving refresh. Keep the selector's action handlers outside the fzf script and invoke normal CLI commands.

### Optional global persistence

Document tmux-resurrect/continuum as optional user-installed tools, not dependencies. Never allow their broad save/restore operations to be presented as the manager's borrowed-only layout save/restore.

## 8. Code reuse policy

Before copying code from any plugin:
- inspect the exact source file and its license;
- preserve license notices and attribution;
- isolate copied code behind a narrow interface;
- avoid copying an entire plugin where a short native tmux wrapper is clearer;
- record upstream version/commit and local modifications;
- prefer behavioral inspiration over code duplication when the code is tightly coupled to plugin conventions.

## 9. Prototype experiments required

1. Move an existing pane from a detached home session into a target window using `join-pane`; verify process continuity.
2. Return it to a home window while preserving the home session identity.
3. Move a full window between sessions and restore it.
4. Borrow three panes from three different sessions into one working window.
5. Borrow an unmanaged pane from an arbitrary session and record whether its original location can be restored.
6. Save metadata for only manager-owned borrowed panes; add an ordinary pane; restore/replace the borrowed arrangement and prove the ordinary pane is not destroyed or included.
7. Test pane color changes and restoration across supported tmux versions.
8. Test popup + fzf with a tree list and action keys.
9. Simulate missing home session/window and interrupted metadata writes.
10. Test duplicate visible session names and multiple tmux sockets.

## Sources

- tmux-sessionist: https://github.com/tmux-plugins/tmux-sessionist
- fzf-pane-switch.tmux: https://github.com/Kristijan/fzf-pane-switch.tmux
- fzf-pane-switch releases: https://github.com/Kristijan/fzf-pane-switch.tmux/releases
- tmux-fzf-jump: https://github.com/cengebretson/tmux-fzf-jump
- tmux-resurrect: https://github.com/tmux-plugins/tmux-resurrect
- tmux-resurrect hooks: https://github.com/tmux-plugins/tmux-resurrect/blob/master/docs/hooks.md
- tmux-continuum: https://github.com/tmux-plugins/tmux-continuum
