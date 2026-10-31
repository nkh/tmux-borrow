# Requirements

## 1. Vocabulary

| Term | Meaning |
|---|---|
| Utility | A long-running command or application managed as a movable tmux resource, such as `htop`, `lazygit`, a log tail, REPL, file manager, or debugger. |
| Registered utility | A utility definition stored in configuration. It may accept arguments and define defaults, scope, launch behavior, colors, and lifecycle policy. |
| Ad hoc utility | A utility launched from the command line or chooser without first adding a permanent utility definition. It is still assigned to a session and can be managed, borrowed, returned, and terminated. |
| Instance | One running occurrence of a utility. Multiple instances may come from one registered definition. |
| Home session | The session assigned to an instance as its normal/full-window home. |
| Home window | The window occupied by an instance in its home session. A utility occupies a full window in its home session. |
| Working session/window | The session/window into which a pane or utility is borrowed. |
| Pane | A tmux pane. Borrowing a pane moves the existing pane; it does not restart its process. |
| Borrow | Move an existing pane or utility window into a working context. |
| Borrowed pane | A pane currently away from its home location and tracked by the manager. |
| Borrowed utility | A managed utility instance currently displayed outside its home window/session. |
| Resource identity | Stable manager identity for an instance, independent of its current tmux pane ID, window index, or session name. |
| Instance ID | Unique identity for one running instance. |
| Scope | Whether an instance is shared across user windows or belongs to one user window. |
| Layout | A collection of borrowed resources and their arrangement in a target window. |
| Borrowed-only layout | A saved arrangement containing only manager-tracked borrowed resources. Ordinary panes are excluded. |
| Selector | Interactive popup interface for choosing utilities, layouts, sessions, panes, and actions. |

## 2. Core model

1. A registered utility definition may accept positional arguments and named options.
2. A registered utility may create many instances.
3. Each instance is assigned a home session manually or automatically.
4. Each utility occupies a full tmux window in its home session.
5. A utility can be borrowed into another session/window without restarting its process.
6. Borrowing a pane is not restricted to its declared home session. Any eligible pane in any tmux session can be borrowed; manager-owned utility panes retain their identity and return metadata.
7. Multiple borrowed utilities may coexist in one working window, including utilities originating from different sessions.
8. Borrowed resources can be returned individually or as a group.
9. A current borrowed arrangement can be replaced with another selection or saved layout.
10. The manager must distinguish identical visible session names. Session names may include geometry or descriptive hints, but names are not a reliable unique key. Internal IDs are mandatory.
11. The manager can terminate a borrowed utility from its borrowed location.
12. The manager can list and terminate utilities in home sessions through CLI and interactive selection (fzf or a tree-like selector).
13. A utility may be scoped to a user window (for example, a file manager rooted in that window's project) or shared across user windows.
14. A utility's borrowed pane background can be changed without changing unrelated panes.

## 3. Registered and ad hoc launch behavior

### Registered utilities

- Definitions live in a user-editable configuration file.
- Definitions can accept arguments.
- Configurable fields include command, arguments, home-session assignment, session naming/geometry, scope, split defaults, lifecycle policy, colors, working directory, environment, and launch options.
- A command-line invocation may override any configurable field.
- Values not specified on the command line or in the utility definition use documented global defaults.
- The effective configuration precedence is: explicit CLI override > utility definition > global configuration > built-in default.
- Argument passing must preserve shell argument boundaries. Avoid `eval` and unsafe command-string concatenation.

### Ad hoc utilities

- Ad hoc utilities are not merely run in a temporary pane and forgotten.
- They are assigned to a session, either explicitly by the user or automatically by policy.
- They can be launched into a background/home session and later borrowed into a working window.
- They support the same configurable launch options as registered utilities, through CLI options.
- Any option available in the configuration file must have a corresponding CLI override where it makes sense.
- Unspecified options inherit global configuration defaults, then built-in defaults.
- Ad hoc instances receive stable instance IDs and are listed by the manager.
- A user may optionally promote an ad hoc launch into a registered definition later.

## 4. Home session and storage

- Utilities occupy full windows in their home sessions.
- Session naming may encode geometry or other human-readable metadata, following the useful convention explored in tmuxake.
- Session names must not be the sole source of truth. A user-configurable metadata directory must store stable IDs, utility definitions/instances, home locations, and layout metadata.
- The metadata directory should default to an XDG-compliant user data/state location; the user can override it.
- The implementation must not require writing to `/var`. If the user chooses a system-wide location, permissions and multi-user safety must be explicit.
- Session/window/pane references must be validated at use time because tmux indices and IDs can change or disappear.

## 5. Borrowing and layout behavior

- Borrowing may move a full utility window or one of its panes into a split.
- Borrowing a pane into a split may require an argument such as a path, target, project, or filter. This operation must support an interactive prompt/selector; it cannot be shortcut-only.
- If no split-specific argument is supplied, use the configured default.
- Borrowing a utility as a full window and borrowing a pane into a split are distinct operations.
- A layout may contain more than two borrowed panes.
- Resources may originate from multiple home sessions.
- Return-one and return-all operations must restore resources to their recorded home locations when possible.
- A replace operation changes the manager-owned borrowed arrangement without disturbing ordinary panes.
- Save and restore operations must include only manager-owned borrowed panes/windows.
- Saving a borrowed-only layout must never serialize ordinary working panes as part of the layout.
- Restoring or replacing a layout must never kill, move, resize, or overwrite ordinary working panes except for unavoidable tmux geometry changes caused by a split. This limitation must be documented.
- If the current working window contains no suitable space for a requested split, the user must be asked or a configured policy must decide how to proceed.

## 6. Interactive management and shortcuts

Interactive management is a major project feature.

- tmux already consumes a prefix key. The project must avoid requiring a large new family of memorized key combinations.
- A small number of stable entry shortcuts should open a popup.
- The popup accepts keyboard input and can be implemented as:
  - a minimal key reader/lookup,
  - an fzf-based searchable selector,
  - or a dedicated command-control TUI.
- The UI must support choosing a utility, instance, source session/pane, layout, or action.
- Management actions include borrow, return, return all, replace layout, save layout, launch ad hoc, inspect, edit, and terminate.
- The selector must support both flat and tree-like views where useful.
- The UI should make action keys visible and discoverable.
- A CLI remains available for scripting and direct use.
- The design may use one launcher with separate small UI backends, or several small executables. The implementation decision must preserve composability and avoid a monolith.

## 7. Configuration and editing

- A CLI command opens the configuration file in `$EDITOR`; the user must not need to know its path.
- A CLI command opens a selected layout in `$EDITOR`.
- If multiple layouts/config files exist, the command offers fzf selection or shell completion.
- Bash completion is required for the CLI.
- A first-run configuration wizard is required.
- The wizard creates a minimal valid configuration and explains optional features without forcing the user through every setting.
- Configuration should be human-editable and use a parser appropriate to the implementation language. Do not invent a bespoke complex language.
- A schema/version field and migration strategy are required.

## 8. Lifecycle and termination

- A borrowed utility can be terminated from its borrowed pane.
- A utility in a home session can be terminated by:
  - CLI, using a listable target/instance ID;
  - fzf selector;
  - tree selector.
- Termination must identify the instance, not rely only on a visible session name.
- On process exit, configurable policies include:
  - replace the process with an interactive shell;
  - keep the pane and wait for a key before closing/cleanup;
  - close the pane/window;
  - leave the pane unchanged.
- Lifecycle behavior must distinguish the utility process exiting normally from the pane being killed externally.
- Destructive actions require clear target display and configurable confirmation.

## 9. Colors and visual identity

- Borrowed utility panes can have a configured or per-instance background color.
- Color changes must be scoped to the borrowed pane and restored/cleared when returned, unless explicitly configured as persistent.
- Color must be optional and must not be required to understand state.
- The implementation must account for terminal and tmux color capabilities.

## 10. Implementation constraints

- Small code base, many small utilities; no monolithic blob.
- Unix-style reuse is a primary requirement.
- Bash is preferred. Perl is acceptable for short helpers. Standard utilities such as `sed` and short `awk` programs are acceptable.
- Keep dependencies limited and optional where possible.
- Use tmux-native commands for functionality tmux already provides.
- Do not reimplement pane splitting, resizing, focus, window creation, session switching, or standard navigation.
- Do not build on tmuxake. Its useful architectural parts and isolated code may be inspected and selectively adapted, but its single-extra-pane assumption must not shape this design.
- Plugins may be optional adapters or sources of ideas; the core must not require a large plugin stack.
- Every component must have a narrow responsibility, clear input/output contract, and be independently testable.

## 11. Non-functional requirements

- Safe with multiple tmux servers/sockets.
- Safe with duplicate visible session names.
- Recoverable after manager interruption or tmux server restart where possible.
- Must detect stale metadata and missing resources.
- Must not silently discard ownership metadata.
- Must quote and pass arguments safely.
- Must support headless/background sessions.
- Must provide useful diagnostics without requiring debug mode.
- Must document behavior on tmux versions where required format fields or commands differ.
