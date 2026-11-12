---
title: tum-defs
section: 5
header: tmux-borrow Manual
---

## NAME

tum-defs \[em] the tum utility (`.util`) and layout (`.layout`) definition file format

## SYNOPSIS

`~/.config/tum/<name>.util`

`~/.config/tum/<name>.layout`

## DESCRIPTION

Definitions live in one directory \[em] `~/.config/tum/` (`XDG_CONFIG_HOME`
is respected) \[em] with one file per utility (`<name>.util`) and one file
per layout (`<name>.layout`). Utilities and layouts share the directory.

The format is flat `key:value`, one entry per line: no sections, no
hierarchy, no quoting. The **filename is the name**; there is no `name:`
field inside the file, so name collisions are impossible. Layouts reference
utility files by name; there is no repetition.

Comments: everything after `#` on a line is ignored. A `#` must be
precedced by whitespace or start the line, so values containing `#` (such
as a URL fragment) are not split.

## UTILITY FILE KEYS

The special keys below are reserved. Every **other** `key:value` line is an
**environment key** \[em] it sets an environment variable for the launched
process (see ENVIRONMENT VARIABLES).

| Key               | Required | Meaning                                                                                  |
| ---               | ---      | ---                                                                                      |
| `command`         | yes      | Executable path or name.                                                                 |
| `args`            | no       | Arguments to the command. May contain `{{placeholder}}` tokens filled from `input` keys. |
| `cwd`             | no       | Working directory. May contain `{{placeholder}}` tokens.                                 |
| `slot`            | no       | Default slot key (`0\[en]9`, `a\[en]z`); auto-assigned on conflict, unique within the host window. |
| `input`           | no       | Repeatable; declares a user-input argument prompted at create time (see THE INPUT KEY).  |
| `use-process-env` | no       | If set, environment variables defined in the file are overridden by the calling process's environment when present there. |

`command` is the only required key. A utility runs until you close it
(**tum-close**(1)); there is no exit-policy key.

## ENVIRONMENT VARIABLES

Any `key:value` line that is not a special key is an environment variable:
the key is the variable name, the value is its value. One variable per
line, no `env` prefix, no comma separation.

```
PGPASSWORD: secret
FOO: bar
```

A value may contain any character, including `,` and `=`.

At launch, the spawned process inherits the calling process's environment,
then the file's environment keys are applied on top (file values win over
inherited). The `use-process-env` key changes that order for keys that
also exist in the calling environment:

```
PGUSER: postgres
PGHOST: localhost
use-process-env: yes
```

With `use-process-env: yes`, if the user has `PGUSER` exported, that value
is used; otherwise `postgres` from the file is used. The file provides
defaults; the live environment wins for variables the user has set.
Environment values are static \[em] they never contain `{{placeholder}}`
tokens.

## THE INPUT KEY

Some utilities need an argument the user supplies at create time \[em] a
location for a weather report, a file path for a log tail, a query for a
database console. The `input` key declares these; `args`, `cwd`, and
`command` reference them with `{{name}}` placeholders. `input` is
repeatable; each line declares one placeholder:

```
command: curl
args: "-s wttr.in/{{location}}?format={{unit}}"
input: location
input: unit
```

At create time (**tum-new**(1), or the create branch of **tum-borrow**(1)),
every `input` value is prompted in declaration order **before** any tmux
mutation, then substituted into every `{{name}}` token in `args`, `cwd`,
and `command`. **tum-borrow** that reuses an existing instance never
prompts \[em] inputs are collected only when a new instance is created. If
standard input is not a TTY (non-interactive mode), the command fails with
the names of the missing inputs rather than hanging.

Secret values are supplied interactively or via a secret provider, never
stored in definition files; secret prompts read without echoing.

## LAYOUT FILE KEYS

A layout file is flat `key:value`, parsed by the same loop as a utility
file. Two keys are special:

| Key         | Required | Meaning                                                      |
| ---         | ---      | ---                                                          |
| `layout_id` | no       | Layout id stamped on member panes. Defaults to the filename. |
| `focus`     | no       | Which member gets focus when the layout is borrowed. The value is a member name, or `host` to focus the host pane. Defaults to `host`. |

Every other key is a **member entry** (see LAYOUT DSL). There is no
`members:` wrapper and no indentation.

## LAYOUT DSL

Every non-special key in a layout file is a member entry. The key is the
member name (it must match a utility definition filename); the value is its
placement:

```
<member-name>: anchor=<host|member-name>, side=<right|left|top|bottom>, size=<N%|Nc>
```

A complete layout file:

```
layout_id: dev
focus: editor
editor: anchor=host, side=right, size=60%
term: anchor=host, side=bottom, size=20%
logs: anchor=term, side=bottom, size=30%
```

`anchor` defaults to `host`. A member may anchor to another member,
allowing two panes on the same side of the host (above, `logs` anchors
below `term`, so both sit on the bottom while `editor` takes the right).
`side` is required. `size` is a percentage of the anchor or a cell count;
it is optional.

## EXAMPLES

A minimal utility:

```
command: htop
slot: 1
```

A log viewer prompted for its file at create time, with pager defaults
overridable from the shell:

```
command: tail
args: -n 500 -f {{logfile}}
input: logfile
cwd: ~/projects/acme/var/log
slot: l
use-process-env: yes
PAGER: less
LESS: -RiX
```

A three-member layout:

```
layout_id: dev
focus: editor
editor: anchor=host, side=right, size=60%
term: anchor=host, side=bottom, size=20%
logs: anchor=term, side=bottom, size=30%
```

## SEE ALSO

**tum**(1), **tum-borrow**(1), **tum-new**(1), **tum-import**(1),
**tum-keymap**(5)
