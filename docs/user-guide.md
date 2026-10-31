# User guide

This guide describes the intended user experience. The CLI syntax is provisional and will be finalized after a working prototype.

## The basic idea

A utility runs in its own full tmux window in a home session. You can bring that existing running pane or window into the window where you are working. The process keeps running; it is moved, not relaunched. When you are finished, return it to its home.

This is useful for long-lived tools such as a file manager, log viewer, REPL, database console, monitoring dashboard, debugger, or `lazygit`.

## First run

Run the setup wizard:

```sh
tum setup
```

The wizard creates a minimal configuration and a private metadata directory. It asks only for essential defaults, such as the editor, selector preference, home-session policy, and behavior when a utility exits.

Open the configuration without knowing its location:

```sh
tum config edit
```

Open a layout for editing:

```sh
tum layout edit
```

If there are several layouts, the command can use fzf or shell completion to choose one.

## Register a utility

A registered utility has a name and a command definition. It may accept arguments. The exact configuration syntax is still to be selected; conceptually:

```yaml
utilities:
  logs:
    command: tail
    args: ["-F", "/var/log/syslog"]
    scope: shared
    home_session: auto
    on_exit: shell
```

Launch it:

```sh
tum launch logs
```

Pass arguments to the registered command:

```sh
tum launch logs -- /var/log/auth.log
```

The definition can provide default arguments and the invocation can add or override arguments according to the documented argument policy. CLI options override utility settings; settings not specified by the invocation inherit from the definition, global configuration, and built-in defaults.

## Launch an ad hoc utility

An ad hoc utility does not need a registered definition:

```sh
tum launch --adhoc --name "build output" --session auto -- tail -F ./build.log
```

It is still assigned to a session and tracked as an instance. It can remain in a background/home session and be borrowed later.

Ad hoc launches accept the same meaningful launch options as registered utilities. For example:

```sh
tum launch --adhoc \
  --name "project REPL" \
  --session "project-tools" \
  --scope window \
  --cwd "$PWD" \
  --on-exit wait \
  --background "#263238" \
  -- irb
```

Any option omitted here uses the configured global default. There is no separate “temporary and unmanaged” launch path hidden behind the ad hoc label.

## Borrow a utility

The shortest route is the popup selector:

```sh
tum ui
```

Choose a utility or instance, then choose whether to borrow its full window or its pane into the current window.

The CLI equivalent is:

```sh
tum borrow logs
tum borrow --instance 8f31c2 --as pane
tum borrow --instance 8f31c2 --as window
```

The same utility can have several instances. The selector should show its name, arguments/working directory summary, scope, home session, and current state.

## Borrow a pane from any session

The general pane selector can browse all sessions, windows, and panes, not only registered utility home sessions:

```sh
tum borrow --select-pane
```

Or specify a tmux target:

```sh
tum borrow --pane '%17' --into-window 'work:2' --as split
```

A pane not managed by this project may be borrowed, but the manager cannot promise an automatic return to a known home unless its original location is captured and remains valid. The selector must clearly distinguish managed utilities from ordinary panes.

## Borrow into a split with an argument

Some utilities need a value when placed into a split. A file manager may need a path; a database tool may need a connection name; a profiler may need a target process.

Pass it directly:

```sh
tum borrow logs --as split --arg "/var/log/auth.log"
```

Or omit it and let the popup ask:

```sh
tum ui borrow --split
```

If neither CLI nor interactive input provides a value, the configured split default is used. If no default exists and the argument is required, the operation must stop with a clear message rather than launch with a guessed value.

## Multiple borrowed utilities

A working window may contain several borrowed panes from different sessions. Each resource is tracked separately.

```sh
tum list borrowed
tum return --instance 8f31c2
tum return --all
```

`return --all` returns manager-tracked borrowed resources in the defined scope. It does not affect ordinary panes.

## Save and replace a borrowed-only layout

Save the current borrowed arrangement:

```sh
tum layout save review-tools
```

The saved layout contains only borrowed resources managed by this project. It does not include ordinary panes in the working window.

List layouts:

```sh
tum layout list
```

Restore or replace the current borrowed arrangement:

```sh
tum layout apply review-tools
tum layout replace review-tools
```

A replacement may return current borrowed resources and borrow the new set. Ordinary panes remain in place; tmux may necessarily adjust their geometry when splits are added or removed.

## Colors

Set a borrowed pane's background color:

```sh
tum color set --instance 8f31c2 '#263238'
tum color reset --instance 8f31c2
```

Colors can also be configured on a utility definition or at launch. By default, a temporary borrowed color is cleared when the resource returns home.

## Terminate utilities

Terminate a borrowed utility:

```sh
tum kill --instance 8f31c2
```

List utilities in home sessions:

```sh
tum list instances
```

Terminate one by ID:

```sh
tum kill --instance 8f31c2
```

Or use the interactive tree/fzf selector:

```sh
tum ui
```

Choose the instance and select **Terminate**. The UI must show the instance identity and location before confirmation.

## Edit and inspect

```sh
tum config show
tum config edit
tum layout list
tum layout edit review-tools
tum inspect --instance 8f31c2
tum list sessions
tum list panes
```

Bash completion should complete commands, registered utility names, instance IDs, and layout names. Where there are many choices, fzf selection is available.

## Exit behavior

Each utility can define what happens when its command exits:

- `shell`: replace the utility process with an interactive shell.
- `wait`: keep the pane and wait for a key before cleanup.
- `close`: close the pane/window.
- `leave`: leave the pane as-is.

The configured default is used unless the utility definition or launch command overrides it.

## Shortcuts

The recommended default is deliberately small:

- One prefix shortcut opens the management popup.
- Optional second shortcut opens the same popup directly in a return-oriented view.

All other actions are selected inside the popup or run through the CLI. The exact keys are configurable. The project should not compete with tmux's existing navigation, resize, zoom, copy-mode, or window-management bindings.
