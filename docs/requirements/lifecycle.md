# Utility lifecycle

| State       | Meaning                                     |
| ---         | ---                                         |
| `starting`  | Launch is in progress                       |
| `home`      | Running in its managed home pane            |
| `borrowed`  | Running in a working window                 |
| `returning` | Return operation is in progress             |
| `stopped`   | Process ended and pane is inactive          |
| `failed`    | Operation failed and needs inspection       |
| `unknown`   | Live tmux state cannot be reconciled safely |

## Start

Resolve config and CLI overrides; collect required arguments; validate executable and working directory; allocate stable instance ID and home location; journal intent; create managed window and launch argv; verify pane/PID; commit state. On failure, clean up only resources created by this attempt.

## Borrow

Resolve instances; verify running and not already borrowed; collect every required argument before moving anything; journal source and target; use `join-pane` or `move-window`; verify location; record host association and temporary appearance snapshot; commit. Batch failure should roll back completed moves when safe, otherwise report a precise partial result.

## Return

Journal; move pane/window home; restore temporary appearance; clear host association; verify and commit. If home session/window was deleted, recreate it from metadata rather than selecting a same-named session.

## Stop and process exit

Stopping a borrowed utility is allowed after identifying its exact managed pane. Require confirmation unless `--yes`. Never kill the host or an ordinary pane. Exit policies: `wait` (default), `shell`, or `close`.

## Idle behavior

Default is `keep_running`. Optional per-utility hooks may run on idle, borrow, return, or stop. Do not send generic SIGSTOP/SIGCONT by default: arbitrary programs may lose connections, locks, or state. Hook failures must be reported and must not be silently treated as success.
