# Arguments and configuration precedence

## Argument representation

Store executable arguments as an ordered array (`argv`), never one shell command string. This preserves spaces and prevents re-parsing.

```toml
[utility.ranger]
command = "/usr/bin/ranger"
default_args = []
cwd = "/work"
instance_policy = "per_window"
required_args = ["root"]

[utility.ranger.argument.root]
prompt = "Directory to browse"
type = "directory"
persist = false
```

## Presets

An argument preset is a named set of values for declared arguments of one utility. It is not another utility definition.

```toml
[preset.ranger.project-a]
utility = "ranger"
values = { root = "/work/project-a" }
portable = true
```

Secret values must be supplied interactively or by a supported secret provider. Never put them in ordinary config, layout files, or logs.

## Precedence

Lowest to highest: built-in defaults; global config; utility definition; layout item or selected preset; command-line override. An explicitly supplied empty CLI value is still an override.

## Ad-hoc launch

Manager options precede `--`; arguments after `--` are passed verbatim as argv. Unspecified manager options use configured defaults.

```sh
tum run --name scratch --cwd "$PWD" -- /usr/bin/htop -d 10
```

Do not use `sh -c` unless the user explicitly selects a shell as the executable.

## Prompting

Prompt for missing required values in declaration order. For a layout, collect all values before any tmux mutation. In non-interactive mode, fail with the names of missing values.
