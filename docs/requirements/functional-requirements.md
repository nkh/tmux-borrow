# Functional requirements

Priority: P0 is required for a useful first release; P1 follows; P2 is optional.

| ID     | Priority | Requirement          | Acceptance condition                                      |
| ---    | ---      | ---                  | ---                                                       |
| FR-001 | P0       | Register definitions | Add and list named definitions                            |
| FR-002 | P0       | Launch utility       | Start in managed home window                              |
| FR-003 | P0       | Ad-hoc launch        | CLI options override defaults                             |
| FR-004 | P0       | Multiple instances   | One definition has several instances                      |
| FR-005 | P0       | Borrow pane          | Move existing process pane into target                    |
| FR-006 | P0       | Return pane          | Restore pane to recorded home                             |
| FR-007 | P0       | List instances       | Show ID, definition, state, home/current location         |
| FR-008 | P0       | Selection            | Auto-select unique; resolve ambiguity explicitly          |
| FR-009 | P0       | fzf                  | Search instances; batch-select only for batch actions     |
| FR-010 | P0       | Required arguments   | Prompt before launch or move                              |
| FR-011 | P0       | Safe argv            | Preserve argument boundaries; never eval                  |
| FR-012 | P0       | Stop instance        | Stop a managed instance from any location                 |
| FR-013 | P0       | Exit policy          | `wait`, `shell`, or `close` behavior                      |
| FR-014 | P0       | Save layout          | Save managed panes only                                   |
| FR-015 | P0       | Restore layout       | Do not replace or rearrange ordinary panes wholesale      |
| FR-016 | P0       | Config editor        | Open config through `$EDITOR`                             |
| FR-017 | P0       | Layout editor        | Open named layout through `$EDITOR`                       |
| FR-018 | P0       | Wizard/template      | Register via readline wizard or template append           |
| FR-019 | P1       | Clone layout         | Create destination layout without moving source resources |
| FR-020 | P1       | Per-window instances | Associate an instance with one working window             |
| FR-021 | P1       | Shared instances     | Reuse one instance across windows, one borrow at a time   |
| FR-022 | P1       | Window borrow        | Move a complete managed window                            |
| FR-023 | P1       | Host association     | Preserve association for manager-mediated host moves      |
| FR-024 | P1       | Lifecycle hooks      | Optional utility-specific idle/borrow/return hooks        |
| FR-025 | P1       | Temporary appearance | Restore pane options on return                            |
| FR-026 | P1       | Argument presets     | Named argument sets                                       |
| FR-027 | P1       | Bash completion      | Complete commands, definitions, instances, layouts        |
| FR-028 | P2       | Tree selector        | Hierarchical sessions/windows/instances view              |
| FR-029 | P1       | Argument save policy | Omit, preset reference, or approved non-secret values     |
| FR-030 | P1       | Recovery             | Reconcile interrupted operations                          |

## Instance policies

- `shared`: one instance may be borrowed by different working windows, but only one at a time because a pane cannot exist in two windows.
- `per_window`: an instance is associated with one stable manager record for a working tmux window. If none exists for the target, offer to create one.

## Borrow modes

`pane` moves one managed pane into a target window. `window` moves a complete managed window to another session. These are distinct operations.

## Host association

The host pane is the pane beside which the utility is borrowed. tmux does not make it a parent. The manager records the relationship and guarantees it for movement commands issued through the manager. External tmux movement may be reconciled on the next manager operation; do not claim universal automatic following.

## Arguments and layouts

Collect all missing required values before starting a batch borrow or restoring a layout. A layout may store no values (default), a named preset reference, or explicitly approved non-secret values. Secret values are never stored. On process exit, default policy is `wait` so the exit result remains visible.
