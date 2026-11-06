# Configuration

Human-edited utility definitions and layouts use TOML. Runtime state is SQLite under `$XDG_STATE_HOME/tmux-utility-manager/`, falling back to `$HOME/.local/state/tmux-utility-manager/`. Use `tum config edit` and `tum layout edit NAME`; users need not know file paths.

```toml
[utility.files]
command = "/usr/bin/mc"
default_args = []
cwd = "/work"
instance_policy = "per_window"
exit_policy = "wait"

[utility.logs]
command = "/usr/bin/tail"
default_args = ["-F", "/var/log/syslog"]
cwd = "/"
instance_policy = "shared"
exit_policy = "wait"
```

Precedence: built-in defaults, global config, utility definition, layout/preset, CLI overrides. Values after `--` are passed unchanged to the utility.
