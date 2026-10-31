# Architecture and component boundaries

## Design direction

Treat the manager as a small orchestration layer over tmux, not as a new terminal multiplexer. tmux owns the live pane/window/session graph. The manager owns utility definitions, instance identity, home-location intent, borrowed-resource ownership, layouts, and interactive workflows.

A practical design is one thin command dispatcher plus small executable helpers. The dispatcher should not contain the business logic.

## Proposed components

| Component        | Responsibility                                                         | Interface shape                                     |
| ---              | ---                                                                    | ---                                                 |
| `tum`            | Minimal CLI dispatcher and help                                        | `tum <verb> [args...]`                              |
| `tum-config`     | Read/validate effective configuration and precedence                   | print normalized key/value or NUL-delimited records |
| `tum-state`      | Read/write instance and layout metadata atomically                     | `list`, `get`, `put`, `delete`, `recover`           |
| `tum-tmux`       | Narrow wrappers around tmux operations                                 | create/move/return/inspect resource                 |
| `tum-launch`     | Resolve config + CLI overrides and launch registered/ad hoc instance   | arguments in, instance ID out                       |
| `tum-borrow`     | Borrow a utility/window/pane into target context                       | source ID + target + mode                           |
| `tum-return`     | Return one or more tracked resources home                              | instance/resource IDs                               |
| `tum-layout`     | Save/list/show/edit/restore/replace borrowed-only layouts              | layout name + target window                         |
| `tum-list`       | Produce machine-readable inventory of sessions/windows/panes/instances | stable records                                      |
| `tum-select`     | Interactive chooser front-end                                          | action + candidate records                          |
| `tum-edit`       | Open config/layout in `$EDITOR`; selection/completion                  | config/layout target                                |
| `tum-completion` | Bash completion                                                        | completion candidates                               |
| `tum-wizard`     | First-run config generation                                            | prompts; writes config                              |
| `tum-cleanup`    | Detect stale metadata and reconcile missing resources                  | report or repair                                    |

The initial implementation may combine a few tiny components if that reduces process overhead, but each responsibility must remain separately callable and testable.

## Data model

### Utility definition

- `name`: human-readable registered utility name.
- `command`: executable path/name.
- `args`: default argument vector.
- `scope`: `window` or `shared`.
- `home_session`: explicit name/template or auto-assignment policy.
- `working_directory`: optional default.
- `split_argument`: optional prompt/default/argument mapping.
- `background`: optional pane background color.
- `on_exit`: shell, wait, close, or leave.
- `environment`: optional key/value map.
- `window_name`: optional title.
- `tags`: optional selector categories.

### Instance

- `instance_id`: generated stable ID, never inferred from tmux indices.
- `definition`: registered utility name or `adhoc`.
- `display_name`: user-facing label.
- `argv`: actual command and argument vector used.
- `scope_key`: user-window identity for window-scoped instances.
- `home_session_id`: stable manager-side session identity.
- `home_session_name`: current visible name (not unique).
- `home_window_id`: tmux window ID where possible.
- `current_session_id`, `current_window_id`, `current_pane_id`: current location.
- `state`: home, borrowed, missing, exited, stale, or unknown.
- `created_at`, `last_seen_at`.

### Layout

- `layout_id`, `name`, `version`.
- `target_scope`: optional target session/window identity.
- `resources`: only manager-owned borrowed resource IDs.
- `arrangement`: relative split/layout description.
- `focus_resource`: optional active borrowed resource.
- `ordinary_panes`: explicitly absent; never serialized.

## Identity and session naming

Session names are labels, not keys. Two sessions may both be named `dev-120x40`; metadata must distinguish them using a stable ID associated with tmux's session ID and server socket identity. Session geometry in names may be a useful convention, not a required encoding.

The metadata directory is configurable, with an XDG default. Use atomic writes (temporary file + rename), restrictive permissions, and a versioned format. Avoid storing secrets in metadata.

## Configuration precedence

For each setting:

1. Explicit CLI option.
2. Registered utility definition.
3. User global configuration.
4. Built-in default.

Ad hoc launches skip step 2. A command-line option should map to every configurable launch property where a meaningful override exists. A normalized effective configuration should be inspectable before launch (`tum launch --dry-run ...` is a candidate).

Arguments must be represented as an argument vector, not a shell string. A utility's configured default args and invocation args need a documented append/replace rule. Proposed default: append invocation positional args after configured default args; provide an explicit `--replace-args` option if replacement is needed.

## Scope model

- `window`: create a separate instance per user window/scope key. Example: file manager rooted in each project window.
- `shared`: reuse one instance across user windows where possible. Example: a shared monitoring process or system dashboard.
- Scope identity must not depend solely on the current active window index. Store a stable window identity while the window exists; define behavior after window recreation.

## Borrowing model

Two distinct resource operations:

1. **Borrow utility window**: move its full home window into the target session or expose it as a window, preserving the running process.
2. **Borrow utility pane**: move the pane into a split in a target window. If a split argument is required, obtain it from CLI or interactive prompt. Use tmux's join/move operations; do not recreate the process.

Additionally, the general pane-borrow operation can select eligible panes from any session, including non-home sessions. Non-manager-owned panes can be borrowed, but cannot be returned to a manager-known home unless the user explicitly chooses/records a return destination. The selector must make ownership and returnability visible.

## Interactive UI strategy

Recommended initial approach: a single `tum-select` entry point with pluggable backends:
- `fzf` backend for searchable lists and tree-like presentation.
- minimal key-reader backend for small fixed menus and environments without fzf.
- future TUI backend only if interaction complexity justifies it.

Keep actions in ordinary CLI subcommands. The UI should call those commands rather than contain separate implementations. This keeps keyboard UI replaceable and all actions scriptable.

A small number of tmux bindings should open the selector in a popup. Avoid a large key map. The popup is the control surface for utility and layout selection, not a new set of tmux navigation keys.

## State and failure handling

- A tmux pane ID such as `%17` is useful for live lookup but not a permanent identity.
- Record both stable manager identity and current tmux IDs.
- Before moving/returning/killing, revalidate the pane/session/window.
- If a home session/window no longer exists, offer recovery choices: recreate home, choose a destination, leave borrowed, or forget metadata.
- If the manager crashes mid-operation, reconcile metadata against tmux state on next invocation.
- Do not delete metadata merely because a tmux lookup temporarily fails.
- Operations affecting multiple resources should be staged and report partial success.

## Security and shell safety

Never build commands using `eval`. Keep argv boundaries. Treat utility commands and arguments as data. Validate names used in file paths. Quote all paths. Use `umask 077` for private state. Avoid sourcing generated state files as shell code.
