# Managing utilities

Register with `tum define add --wizard` or append a starter block with `tum define add --template`. Define executable path, argv defaults, working directory, instance policy, exit policy, and any required arguments.

Start with `tum run NAME`. A definition may have multiple instances. An ad-hoc command uses the same manager options:

```sh
tum run --name scratch --cwd "$PWD" -- /usr/bin/top -b
```

Arguments after `--` are passed as argv and are not evaluated as shell text. Use `tum list` to inspect definitions/instances. Stop only manager-owned instances with `tum stop --instance ID` or `tum stop --fzf`.
