# CLI command index

Executable: `tmux-utility-manager`; optional short alias: `tum`.

| Command                 | Purpose                                      |
| ---                     | ---                                          |
| `list`                  | List definitions and instances               |
| `define add`            | Add definition by template or wizard         |
| `define edit NAME`      | Open definition in `$EDITOR`                 |
| `define remove NAME`    | Remove after checking active instances       |
| `run NAME`              | Start registered utility                     |
| `run -- ...`            | Start ad-hoc utility                         |
| `borrow`                | Borrow selected instance into current window |
| `return`                | Return selected borrowed instance            |
| `stop`                  | Stop selected managed instance               |
| `layout list`           | List layouts                                 |
| `layout add`            | Add layout by template or wizard             |
| `layout edit NAME`      | Edit layout in `$EDITOR`                     |
| `layout save NAME`      | Save managed panes in current arrangement    |
| `layout restore NAME`   | Restore layout                               |
| `layout clone SRC DEST` | Clone layout definition                      |
| `config edit`           | Open main config in `$EDITOR`                |
| `popup`                 | Open interactive manager                     |
| `doctor`                | Check dependencies and reconcile state       |

## Selection and options

If exactly one instance matches, select it automatically. If several match, require `--instance ID` or interactive selection. `--fzf` selects matching instances; multi-select is allowed only for batch-capable commands.

Common options: `--instance ID`, `--fzf`, `--all` (only where documented), `--yes`, `--prompt`, `--format table|json`, and `--` to end manager options and pass the remaining argv to the utility.

`define add` and `layout add` accept `--template` (append a commented block) or `--wizard` (readline questions). If neither is supplied interactively, offer the choice; non-interactive use must specify one.

## Examples

```sh
tum list
tum run ranger
tum run --name scratch --cwd "$PWD" -- /usr/bin/htop
tum borrow --fzf
tum return --instance 2f0d...
tum layout restore project
tum layout clone project project-copy
tum config edit
```

Freeze exact option names before implementation and keep generated help/completion synchronized with this reference.
