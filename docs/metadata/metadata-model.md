# Metadata model

## Storage decision

Use SQLite for authoritative runtime metadata; use TOML for human-edited definitions and layouts. SQLite provides transactions, foreign keys, uniqueness constraints, and concurrent readers. This proposal therefore requires the `sqlite3` CLI. Store the database at `$XDG_STATE_HOME/tmux-utility-manager/state.db`, falling back to `$HOME/.local/state/tmux-utility-manager/state.db`.

## Identifiers

Generate UUIDs for definitions, instances, layouts, and working-window records. tmux IDs (`$N`, `@N`, `%N`) are runtime references only. Never use display names or pane indexes as primary keys.

## Tables

### `utility_definition`

| Column        | Type        | Meaning                       |
| ---           | ---         | ---                           |
| `id`          | TEXT PK     | Stable definition ID          |
| `name`        | TEXT UNIQUE | User-facing name              |
| `config_path` | TEXT        | TOML source                   |
| `config_hash` | TEXT        | Hash of normalized definition |
| `created_at`  | TEXT        | UTC timestamp                 |

Executable, argv, hooks, and policy remain in TOML. The database stores identity and a hash to detect changes.

### `utility_instance`

| Column                | Type    | Meaning                      |
| ---                   | ---     | ---                          |
| `id`                  | TEXT PK | Stable instance ID           |
| `definition_id`       | TEXT FK | Definition used              |
| `state`               | TEXT    | Lifecycle state              |
| `home_session_id`     | TEXT    | Live tmux session ID         |
| `home_session_name`   | TEXT    | Recreate hint, not identity  |
| `home_window_id`      | TEXT    | Live tmux window ID          |
| `home_window_name`    | TEXT    | Recreate hint                |
| `pane_id`             | TEXT    | Current tmux pane ID         |
| `pid`                 | INTEGER | Process ID, if known         |
| `workspace_window_id` | TEXT    | Stable working-window record |
| `current_session_id`  | TEXT    | Current session ID           |
| `current_window_id`   | TEXT    | Current window ID            |
| `host_pane_id`        | TEXT    | Host pane while borrowed     |
| `borrow_mode`         | TEXT    | `pane` or `window`           |
| `created_at`          | TEXT    | UTC timestamp                |
| `updated_at`          | TEXT    | UTC timestamp                |

### `workspace_window`

| Column           | Type    | Meaning                |
| ---              | ---     | ---                    |
| `id`             | TEXT PK | Stable manager ID      |
| `tmux_window_id` | TEXT    | Current tmux window ID |
| `session_id`     | TEXT    | Current session ID     |
| `created_at`     | TEXT    | UTC timestamp          |

### `layout`

| Column        | Type        | Meaning          |
| ---           | ---         | ---              |
| `id`          | TEXT PK     | Stable layout ID |
| `name`        | TEXT UNIQUE | User-facing name |
| `config_path` | TEXT        | TOML source      |
| `created_at`  | TEXT        | UTC timestamp    |

### `operation`

| Column         | Type    | Meaning                                 |
| ---            | ---     | ---                                     |
| `id`           | TEXT PK | Operation ID                            |
| `kind`         | TEXT    | start/borrow/return/stop/restore/clone  |
| `phase`        | TEXT    | planned/running/partial/complete/failed |
| `payload_json` | TEXT    | Validated operation details, no secrets |
| `started_at`   | TEXT    | UTC timestamp                           |
| `updated_at`   | TEXT    | UTC timestamp                           |

### `appearance_snapshot`

| Column         | Type       | Meaning                                   |
| ---            | ---        | ---                                       |
| `instance_id`  | TEXT PK/FK | Instance                                  |
| `options_json` | TEXT       | Original pane options changed temporarily |
| `captured_at`  | TEXT       | UTC timestamp                             |

## Example utility definition

```toml
[utility.logs]
command = "/usr/bin/tail"
default_args = ["-F", "/var/log/syslog"]
cwd = "/"
instance_policy = "shared"
exit_policy = "wait"

[utility.logs.lifecycle]
idle_policy = "keep_running"
```

## Example layout

```toml
[layout.project]
name = "project"

[[layout.project.items]]
utility = "files"
instance_policy = "per_window"
destination = "current_window"
argument_policy = "omit"

[[layout.project.items]]
utility = "logs"
instance_policy = "shared"
destination = "current_window"
argument_policy = "preset"
preset = "project-default"
```

## Transactions and locking

Use SQLite transactions for metadata changes. Use `BEGIN IMMEDIATE` when reserving/changing instance state. Enforce one active borrow per instance transactionally. Do not hold a write transaction while waiting for user input: collect arguments first, then acquire the transaction and revalidate. Set a bounded busy timeout and report contention clearly. The operation journal records tmux side effects that cannot join the database transaction.

## Migration and safety

Store `schema_version`; run ordered migrations transactionally where possible. Back up before destructive migrations. Refuse to write if the database schema is newer than the program. Restrict state/config permissions to the user. Never store secret arguments in operation payloads or logs. If the database is lost, do not claim live panes without verifiable manager markers.
