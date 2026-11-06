# Resource ownership

The manager may move or stop only panes it can prove it owns. Proof requires a matching instance record, manager marker, and verified live pane identity. A pane name or matching command line alone is insufficient.

| Resource                 | Owner            | Manager may move?      | Manager may stop?    |
| ---                      | ---              | ---:                   | ---:                 |
| Managed utility pane     | Manager instance | Yes                    | Yes, explicit action |
| Managed home placeholder | Manager          | Recreate/move          | Yes                  |
| Ordinary user pane       | User             | No                     | No                   |
| User working window      | User             | Add managed panes only | No                   |
| Managed utility window   | Manager          | Yes                    | Yes, explicit action |

The host pane remains user-owned. The manager may use its ID as an insertion anchor but must not alter its process. If it disappears, mark the association orphaned; do not guess a replacement based on position.

Pane borrowing moves one managed pane into an existing window. Window borrowing moves a complete managed window, including its panes. Layouts contain only managed utility panes. They may record a host pane as an insertion anchor but must not serialize ordinary pane contents, durable identity, size, or arrangement.
