# tmux-borrow — the keymap

## A shortcut-driven way to drive every `tum` command, grouped so it's memorizable.

> **Scope.** This document defines the key-binding scheme for tmux-borrow. It is a thin layer over the CLI defined in `tmux-borrow-requirements.md`: every binding shells out to the same `tum` commands scripts use, so the keymap and the CLI can never drift apart. The requirements pin one shortcut directly — flip-flop on `H` — and leave the rest to this keymap. Where the keymap adds bindings, commands, or options not in the requirements, they are flagged as **keymap-proposed**; everything else mirrors the requirements exactly.

---

## Why a keymap at all

Typing `tum borrow htop` is fine for a script. It is not fine for the verb you hit forty times a session. Borrow, flip-flop, and close are reflexes — you want them at two or three keystrokes, not a typed sentence.

The design goals, in priority order:

1. **Fast for the daily loop.** Borrow, flip-flop, and close must be reflexes.
2. **Collision-free with tmux.** Nothing steals tmux's own prefix bindings.
3. **Memorizable.** Commands grouped under mnemonic leaders; uppercase = stronger variant; one mental map covers everything.
4. **Complete.** Every command in the requirements is reachable from the keyboard.
5. **Configurable.** Every key is remappable; the bindings are generated from tmux options.

---

## Design principles

These rules generate the whole keymap. Once you internalize them, you can derive any binding without looking it up.

1. **Flip-flop is bound directly to `H`, per the requirements.** The requirements specify `<prefix> H <slot>`, `<prefix> H`, and `<prefix> H` with `--interactive` for flip-flop. `H` (capital) is collision-safe — tmux has no default `prefix H` binding — so it lives directly in the prefix table, exactly as the requirements say. This is the one shortcut the requirements pin; the keymap honors it verbatim.
2. **The `t` leader scopes the remaining verbs into tmux-borrow's namespace.** The natural mnemonic keys for the other verbs collide with tmux defaults (`x` = kill-pane, `p` = previous-window, `c` = new-window, `n` = next-window, `l` = last-window, `s` = choose-session). After your tmux prefix, `t` enters "tum mode," and every subsequent key is read from tum's own key-tables, so none of these collide. `H` is the exception: it is safe, so it stays direct.
3. **Single key = common verb; `<group> <action>` = family.** The things you do constantly (borrow, close, push, pop, import) are single keys right after the leader. Everything that manages nouns (layout, list, config) is a two-key chord: group leader, then action.
4. **Uppercase = stronger / broader variant.** `B` borrows new (vs `b` borrow existing-or-create); `P` pops (vs `p` push); `I` imports named (vs `i` anonymous). Capital always means "more."
5. **Mnemonics mirror the CLI verbs.** `b`orrow, `x` (close/kill), `p`ush, `i`mport, `l`ayout, `g`o (list), `c`onfig, `u` (popup, the universe). Where the CLI has a name, the key is its first letter.
6. **`Esc`/`q` always cancels, side-effect free.** From the leader, from any sub-group, or mid-prompt: cancel returns you to the root key-table with tmux state unchanged.

---

## The chain

There are two entry styles, and they coexist:

```
<prefix>  H  <slot>          →  flip-flop (direct, per requirements)
<prefix>  t  <key>           →  the other verbs (grouped, collision-safe)
<prefix>  t  <group> <key>   →  a family action
```

- **`<prefix>`** is your normal tmux prefix (default `C-b`; many users remap to `C-a` or `Space`). The keymap never assumes a particular prefix.
- **`H`** enters the `tum-flip` sub-table directly from the prefix table. The next key is a slot (`0`–`9`, `a`–`z`), `Enter` (focused), or `?` (chooser).
- **`t`** enters the `tum-root` key-table. For leaves, the action fires and you return to normal. For group leaders, you drop into a sub-table for one more key.

The shortest path to the most common action is two keystrokes:

```
C-b   H   1      →   flip-flop slot 1 (hide if shown, show if hidden)
```

Borrow is three:

```
C-b   t   b      →   borrow (interactive chooser)
```

If you find the double prefix (`C-b` then `t`) too heavy, you can bind a **no-prefix entry key** (a key in tmux's `root` table) that drops you straight into `tum-root` — no tmux prefix at all. See "No-prefix entry" below; the short version is that `F12` is the safe choice and `M-t` is a footgun.

---

## Master shortcut table

Every binding, in one view. "Direct" = bound in the prefix table (no `t` leader); "Leaf" = fires immediately after the leader; "Group" = opens a sub-table for one more key; "Sub" = opens a sub-table that reads a slot.

The "CLI" column shows the command each binding drives. Commands marked **(proposed)** are keymap-proposed names for actions the requirements describe but do not name (`flip`, `close`, `popup`, `cheatsheet`); the rest are requirements-explicit.

| Key     | Type  | Action                                         | CLI                                |
| ---     | ---   | ---                                            | ---                                |
| `H`     | Sub   | Flip-flop (reads a slot) — direct, per req.    | `tum flip [<slot>]` **(proposed)** |
| `t b`   | Leaf  | Borrow (interactive chooser)                   | `tum borrow --interactive`         |
| `t B`   | Leaf  | Borrow new (always create, interactive)        | `tum borrow --new --interactive`   |
| `t x`   | Leaf  | Close (context-aware kill-pane)                | `tum close` **(proposed)**         |
| `t p`   | Leaf  | Push the focused borrowed pane onto the stack  | `tum push`                         |
| `t P`   | Leaf  | Pop the top of the stack to the current host   | `tum pop`                          |
| `t i`   | Leaf  | Import the current pane (anonymous, temporary) | `tum import`                       |
| `t I`   | Leaf  | Import the current pane (named, saved to file) | `tum import` (prompts for name)    |
| `t u`   | Leaf  | Open the popup (master action menu)            | `tum popup` **(proposed)**         |
| `t ?`   | Leaf  | Cheatsheet overlay                             | `tum cheatsheet` **(proposed)**    |
| `t l`   | Group | Layout family                                  | —                                  |
| `t g`   | Group | Go / view (listings)                           | —                                  |
| `t c`   | Group | Config family                                  | —                                  |
| `t q`   | Leaf  | Cancel (back to root)                          | —                                  |
| `t Esc` | Leaf  | Cancel (back to root)                          | —                                  |

---

## Core verbs (leaves, no group)

These are the daily reflexes. They fire directly off `t` and return you to the root table.

| Key   | Does         | What you see                                                                                                                                  |
| ---   | ---          | ---                                                                                                                                           |
| `t b` | Borrow       | Chooser over all utilities and layouts (no-name mode). Pick one → pane attaches beside the active pane.                                       |
| `t B` | Borrow new   | Same chooser, but always creates a fresh instance rather than reusing a hidden one (the `--new` mode).                                        |
| `t x` | Close        | Context-aware `kill-pane`: from a borrowed pane kills it; from a host with one, kills that; with several, opens the chooser.                  |
| `t p` | Push         | Detaches the focused borrowed pane onto the LIFO push stack (no host). From the host with several borrowed, opens the chooser.                |
| `t P` | Pop          | Attaches the highest-`@tum-push-seq` pane to the current host at its recorded geometry. Consumes it from the stack.                           |
| `t i` | Import anon  | Tags the current pane as a temporary utility (`@tum-source=imported-anon`). No file written; behaves like any utility.                        |
| `t I` | Import named | Prompts for a name, captures command/args/cwd/env from `/proc/$pid/`, writes a `<name>.util` file (`@tum-source=imported-named`).             |
| `t u` | Popup        | The full interactive menu. Every command reachable with arrows/enter — the catch-all for anything without a dedicated binding. **(proposed)** |
| `t ?` | Cheatsheet   | A popup listing every key in this document, grouped — so you never have to leave tmux to remember. **(proposed)**                             |

`t b` follows the requirements' default-mode resolution: an instance already bound to this host is reused; else a hidden instance is borrowed (chooser if several); else a fresh one is created. Close is immediate — no confirmation, mirroring tmuxake. Anonymous import is borrowable, hideable, and closeable like any utility, but is not saved; named import captures at max fidelity from `/proc/$pid/` and the resulting file is meant to be hand-edited.

**Worked example — the core loop.** You're editing in a project window and want the app log beside you, then want it gone:

```
C-b t b          # chooser: pick "logs" → the running tail pane appears beside your editor
# …read, debug…
C-b H 1          # flip-flop slot 1 → the log pane hides into the hidden session; editor untouched
# …need it again…
C-b H 1          # flip-flop slot 1 → the log pane shows again at its last geometry
```

The `tail` process never stopped. Hide is not close — the pane is alive in the hidden session, one keystroke away.

**Worked example — close for real.** The log pane is no longer needed; kill it:

```
C-b t x          # from the borrowed log pane → kill-pane; state gone, nothing to clean up
```

**Worked example — hand a utility to another session.** You borrowed `htop` in session `a` but want it in session `b`:

```
# in session a, focused on htop:
C-b t p          # htop pushed onto the stack; no host
# switch to session b (normal tmux):
C-b t P          # htop pops in beside the current pane at its recorded geometry
```

---

## Flip-flop sub-table — `H …`

Flip-flop toggles a borrowed thing between shown and hidden. It is generic — it does not name a utility, it acts on a slot. Every borrowed thing (a utility, a layout, or a layout member) gets a slot key, declared in its definition or auto-assigned on conflict. The requirements pin flip-flop to `H`; this keymap binds `H` directly in the prefix table (and again under the `t` leader, so it works from either entry path).

After `H`, you press one key:

| Key in `tum-flip` | Does                                                                               | Requirements variant satisfied              |
| ---               | ---                                                                                | ---                                         |
| `0`–`9`, `a`–`z`  | Toggle the thing in that slot. Hide if shown, show if hidden.                      | `<prefix> H <slot>` — toggle by slot        |
| `Enter`           | Toggle the focused pane (the "no slot" case).                                      | `<prefix> H` — toggle focused               |
| `?`               | Open the chooser to pick which attached thing to toggle (for a host with several). | `<prefix> H` with `--interactive` — chooser |
| `q` / `Esc`       | Cancel; back to root, nothing changed.                                             | —                                           |

The requirements' three flip-flop variants all route through this one sub-table. Tmux needs a terminator key after entering a sub-table, so the focused variant (`<prefix> H` in the requirements) is realized as `<prefix> H Enter` here; the chooser variant (`<prefix> H` with `--interactive`) is `<prefix> H ?`.

- A layout's slot toggles all its members as a group; a member's slot toggles just that member.
- Hiding a layout member parks it in the hidden session but keeps its `@tum-layout`; re-showing the layout brings it back.
- Geometry is captured at hide (`@tum-geometry`) and restored on show.

**Worked example — hide one of two borrowed utilities from the host.** You have `htop` (slot `1`) and `lazygit` (slot `2`) beside your editor; hide just `htop`:

```
C-b H 1          # htop hides; lazygit stays shown
C-b H 1          # htop shows again at its last geometry
```

**Worked example — hide the focused pane.** You're on the `htop` pane and want it gone for a moment:

```
C-b H Enter      # htop (the focused pane) hides
```

**Worked example — hide a whole layout.** Layout `dev` (editor, term, logs) is borrowed as slot `d`:

```
C-b H d          # all three members hide together
C-b H d          # all three show again at their last geometries
```

---

## Layout family — `t l …`

Layouts are static definition files (one file per layout, flat `key:value`, filename is the name, in `~/.config/tum/`). Borrowing a layout is the primary layout action and is covered by `t b`: the no-name chooser the requirements define shows all utilities **and** layouts, so picking a layout there borrows all its members into the host window at their declared positions. The layout family itself is just file management.

| Key     | Does                                           | What runs                                                      |
| ---     | ---                                            | ---                                                            |
| `t l e` | Edit a layout file in `$EDITOR` (chooser pick) | chooser picks a layout → `$EDITOR ~/.config/tum/<name>.layout` |
| `t l l` | List layout definition files                   | `ls ~/.config/tum/*.layout`                                    |

These are keymap-level file operations, not `tum` subcommands: the binding runs `$EDITOR` or `ls` directly. Each member of a borrowed layout gets its own slot for individual flip-flop; the layout group gets a slot for group flip-flop. Close one member and the rest continue — the layout is just an id (`@tum-layout`) stamped on the panes, nothing to repair.

**Worked example — bring in a debugging layout.** A layout `debug` (debugger + two logs) is defined:

```
C-b t b          # chooser over utilities and layouts → pick "debug" → all members attach at their declared positions
```

**Worked example — edit a layout's definition.** You want to add a member to `debug`:

```
C-b t l e        # chooser → pick "debug" → $EDITOR opens ~/.config/tum/debug.layout
```

---

## Go / view family — `t g …`

Read-only listings. `g` for "go look."

| Key     | Does                                                     | CLI          |
| ---     | ---                                                      | ---          |
| `t g l` | List all utility panes across all sessions               | `tum ls`     |
| `t g c` | Check for orphans (host dead, utility alive)             | `tum check`  |
| `t g s` | Show the current pane's tum state (glyph + binding info) | `tum status` |

`tum ls` queries `tmux list-panes -a` and shows utility, layout, host, slot, geometry, and state (shown / hidden / pushed / orphan). Orphans — a half-dead binding where the host pane is gone but the utility pane is alive — are marked `!` and left in place; `tum check` lists them for the user to act on (no auto-return).

**Worked example — find what's borrowed where.** Before a deploy, see everything currently attached:

```
C-b t g l        # table: utility, layout, host, slot, geometry, state
```

**Worked example — find orphans.** A host pane died; check what's stranded:

```
C-b t g c        # lists half-orphans: utility panes whose @tum-host is dead, marked !
```

---

## Config family — `t c …`

The "config" is the set of definition files in `~/.config/tum/` plus the `@tum-*` tmux options. There is no `tum config` command in the requirements, so these bindings run shell commands directly.

| Key     | Does                                                         | What runs                |                      |
| ---     | ---                                                          | ---                      | ---                  |
| `t c e` | Open the config directory in `$EDITOR` (utilities + layouts) | `$EDITOR ~/.config/tum/` |                      |
| `t c s` | Show effective `@tum-*` tmux options                         | `tmux show-options -g \  | command grep '@tum'` |

**Worked example — register a new utility.** You want `htop` as a managed utility:

```
C-b t c e        # opens ~/.config/tum/ in $EDITOR → create htop.util:
                 #   command: htop
                 #   tags: monitor
                 #   slot: 1
                 #   on_exit: wait
# save; htop is now borrowable by name
```

The definition keys (`command`, `args`, `cwd`, `env`, `tags`, `slot`, `on_exit`) and the layout DSL are defined in the requirements; this keymap only opens the files for editing.

---

## Popup and help

| Key     | Does                                                                                         |
| ---     | ---                                                                                          |
| `t u`   | Popup — the full interactive menu. Every command reachable with arrows/enter. **(proposed)** |
| `t ?`   | Cheatsheet overlay — every key in this doc, grouped, in a popup. **(proposed)**              |
| `t q`   | Cancel from the leader or any sub-group; back to root, nothing changed.                      |
| `t Esc` | Same as `t q`.                                                                               |

Cancel is a hard guarantee: whether you're at the leader, inside a sub-table, or mid-prompt in a popup, `Esc`/`q` leaves tmux state exactly as it was. No half-moved panes, no partially-hidden slots.

The popup (`t u`) and cheatsheet (`t ?`) are keymap-proposed conveniences. The popup is a TUI menu that delegates to the same CLI commands every binding uses — borrow, borrow new, flip-flop, close, push, pop, import, import named, ls, check, status, edit config. Anything doable in the popup is scriptable; a CLI fix fixes the UI too. If the popup is not implemented, `t ?` (cheatsheet) and the chooser still cover discovery.

---

## Chooser contract (from the requirements)

Every interactive binding passes `--interactive`, which routes the choice through the external chooser script. The contract, fixed by the requirements:

```
tum-chooser <prompt> <items_file> <output_file>
```

- Reads items (one per line) from `items_file`; writes the selection (one line) to `output_file`.
- Exit 0 = a selection was written; non-zero = cancelled (output file empty).
- In a popup, tmux-borrow runs the chooser inside `display-popup` with stdin/stdout bridged through the files — the popup PTY does not carry the caller's stdin or stdout.
- The `@tum-chooser` tmux option selects the script (default `tum-chooser` on PATH). An fzf-based implementation ships as the reference; any script following the contract is a drop-in replacement. The core works with no chooser installed (commands that need one fall back to erroring or to a numbered list).

See `component-analysis.md` for the picker, prompt-library, and other reusable projects behind each component.

---

## Coverage audit — every command is reachable

Every command in the requirements maps to at least one binding.

| Requirements command              | Binding(s)                                        |
| ---                               | ---                                               |
| `tum borrow` (default mode)       | `t b` (chooser; default-mode resolution on pick)  |
| `tum borrow --new`                | `t B`                                             |
| `tum borrow --existing` / `--tag` | CLI / popup (no dedicated key; uncommon)          |
| `tum borrow` (no-name chooser)    | `t b`                                             |
| flip-flop by slot                 | `H <slot>`                                        |
| flip-flop focused                 | `H Enter`                                         |
| flip-flop via chooser             | `H ?`                                             |
| close (context-aware kill-pane)   | `t x`                                             |
| `tum push`                        | `t p`                                             |
| `tum pop`                         | `t P`                                             |
| `tum import` (anonymous)          | `t i`                                             |
| `tum import <name>`               | `t I`                                             |
| `tum ls`                          | `t g l`                                           |
| `tum check`                       | `t g c`                                           |
| `tum status`                      | `t g s`                                           |
| borrow a layout                   | `t b` (chooser includes layouts)                  |
| edit a layout file                | `t l e`                                           |
| edit config dir                   | `t c e`                                           |
| `--interactive` (chooser)         | every interactive binding passes it automatically |
| `tum popup` / `tum cheatsheet`    | `t u` / `t ?` (keymap-proposed)                   |

No requirements command is unreachable; no binding duplicates another's job. Borrowing a layout is covered by `t b` (the no-name chooser the requirements define shows utilities and layouts together), so there is no separate layout-borrow key.

---

## A full session, shortcuts only

To make the muscle memory concrete, here is a realistic afternoon driven entirely by the keymap — no `tum` typed at all.

```
# Define a log viewer (one-time)
C-b t c e          # open config dir in $EDITOR → create logs.util: command: tail, args: -F /var/log/syslog

# Edit for a while in your project window...
# ...bug surfaces, bring the log beside the code:
C-b t b            # chooser → pick "logs" → pane attaches beside your editor, slot 1

# A second service misbehaves; bring its log in too
C-b t b            # chooser → pick "svc-api" → attaches, slot 2

# Hide the first log to focus on the second
C-b H 1            # slot 1 hides; editor + svc-api visible

# Bring a debugger in as part of a layout
C-b t b            # chooser → pick "debug" layout → debugger + two logs attach

# Done debugging; close the svc-api log for real
C-b t x            # focused on svc-api → kill-pane; gone, nothing to clean up

# Push the debugger to another session for a colleague
C-b t p            # debugger pushed onto the stack

# Check health before a deploy
C-b t g c          # check → no orphans
C-b t g l          # ls → see what's still attached
```

Every step is two or three keystrokes. No command typed, no menu navigated except where a chooser is genuinely needed.

---

## Configuration

tmux options are the source of truth. The requirements mandate a few; the keymap proposes the rest for binding generation. Set options once (in your `tmux.conf` or interactively), regenerate the bindings, and source them. You do not hand-maintain two files.

### Requirements-mandated options

These come straight from the requirements and are read by the `tum` runtime.

| Option                | Default       | Meaning                                                        |
| ---                   | ---           | ---                                                            |
| `@tum-chooser`        | `tum-chooser` | The chooser script on PATH (the `--interactive` backend).      |
| `@tum-host-glyph`     | `÷`           | Glyph shown on a host pane with borrowed things attached.      |
| `@tum-borrowed-glyph` | `§`           | Glyph shown on a borrowed pane (plus utility name).            |
| `@tum-hidden-session` | (proposed)    | Name of the shared session where hidden and pushed panes park. |

Orphans — a host pane gone, utility pane alive — are marked with a `!` prefix in `tum ls` and `tum status`, per the requirements.

### Keymap-proposed options (for binding generation) **(proposed)**

These drive `tum bindings tmux`, the keymap-proposed generator that emits the `bind-key` fragment from the options. They are not read by the runtime `tum` commands.

| Option                  | Default       | Meaning                                                                 |
| ---                     | ---           | ---                                                                     |
| `@tum-leader`           | `t`           | The tum leader key, pressed after your tmux prefix.                     |
| `@tum-no-prefix-entry`  | (empty)       | A key bound in tmux's root table to enter tum mode without the prefix.  |
| `@tum-entry-mode`       | `auto_return` | `auto_return` (fire and return to root) or `sticky` (stay in tum mode). |
| `@tum-key-borrow`       | `b`           | Individual key overrides (one per action).                              |
| `@tum-key-borrow-new`   | `B`           |                                                                         |
| `@tum-key-close`        | `x`           |                                                                         |
| `@tum-key-push`         | `p`           |                                                                         |
| `@tum-key-pop`          | `P`           |                                                                         |
| `@tum-key-import`       | `i`           |                                                                         |
| `@tum-key-import-named` | `I`           |                                                                         |
| `@tum-key-popup`        | `u`           |                                                                         |
| `@tum-key-cheatsheet`   | `?`           |                                                                         |

The flip-flop key (`H`) is fixed by the requirements and is not remappable through this table. Any other key omitted keeps its default. Rebinding is always non-destructive: a key left unbound falls through to the popup (`t u`).

### Installing in `~/.tmux.conf`

```sh
# --- tmux-borrow: install the keymap from tum's options ---
run-shell 'tum bindings tmux > ~/.config/tmux/tum-bindings.conf'
source-file ~/.config/tmux/tum-bindings.conf
```

### Generated fragment (illustrative)

The real file is produced and validated by `tum bindings tmux` **(proposed)**. This shows the shape:

```sh
# Generated by `tum bindings tmux` — do not edit by hand; set @tum-* options instead.

# 1. Flip-flop: bound directly to H in the prefix table (per requirements),
#    and again under the t leader so it works from either entry path.
bind-key -T prefix H switch-client -T tum-flip
bind-key -T tum-root H switch-client -T tum-flip

# 2. The leader: <prefix> t  →  enter the tum-root key-table.
bind-key -T prefix t switch-client -T tum-root

# 3. Leaves fire and return to the root table.
#    Interactive bindings run in a popup (they need a TTY for the chooser);
#    non-interactive bindings use run-shell.
bind-key -T tum-root b \
    display-popup -E -w 80% -h 80% 'tum borrow --interactive' \;\
    switch-client -T root
bind-key -T tum-root B \
    display-popup -E -w 80% -h 80% 'tum borrow --new --interactive' \;\
    switch-client -T root
bind-key -T tum-root x \
    run-shell -b 'tum close' \;\
    switch-client -T root
bind-key -T tum-root p \
    run-shell -b 'tum push' \;\
    switch-client -T root
bind-key -T tum-root P \
    run-shell -b 'tum pop' \;\
    switch-client -T root
bind-key -T tum-root i \
    run-shell -b 'tum import' \;\
    switch-client -T root
bind-key -T tum-root I \
    display-popup -E 'tum import' \;\
    switch-client -T root
bind-key -T tum-root u \
    display-popup -E -w 80% -h 80% 'tum popup' \;\
    switch-client -T root

# 4. Flip-flop sub-table: slot key, focused, chooser, cancel.
bind-key -T tum-flip Enter  run-shell -b 'tum flip'      \;  switch-client -T root
bind-key -T tum-flip ?      display-popup -E 'tum flip --interactive' \;  switch-client -T root
bind-key -T tum-flip 1      run-shell -b 'tum flip 1'    \;  switch-client -T root
bind-key -T tum-flip 2      run-shell -b 'tum flip 2'    \;  switch-client -T root
# ... one binding per slot key in use ...
bind-key -T tum-flip q      switch-client -T root
bind-key -T tum-flip Escape switch-client -T root

# 5. Group leaders drop into a sub-table for one more key.
bind-key -T tum-root l switch-client -T tum-layout
bind-key -T tum-root g switch-client -T tum-go
bind-key -T tum-root c switch-client -T tum-config

# 6. One sub-table, shown in full (the others follow the same shape).
bind-key -T tum-layout e display-popup -E 'tum-chooser "Edit layout" <(ls ~/.config/tum/*.layout) /tmp/tum.out && ${EDITOR:-vi} ~/.config/tum/$(basename "$(cat /tmp/tum.out)")' \; switch-client -T root
bind-key -T tum-layout l run-shell -b 'ls ~/.config/tum/*.layout' \; switch-client -T root
bind-key -T tum-layout q       switch-client -T root
bind-key -T tum-layout Escape  switch-client -T root

# 7. Cancel from the leader.
bind-key -T tum-root q       switch-client -T root
bind-key -T tum-root Escape  switch-client -T root
```

**Two implementation notes worth knowing:**

- **Popup vs. `run-shell`.** Any binding that opens the chooser or prompts needs a TTY, so it runs inside `display-popup -E`. Bindings that are genuinely non-interactive (push, pop, close-when-unambiguous) use `run-shell -b` and skip the popup. The generator picks the right one per command.
- **Result feedback.** For silent `run-shell` bindings, the generator emits a `display-message` on success/failure so a failed `t x` doesn't fail invisibly — you'll see "closed htop" or "nothing to close" in the status line.

---

## No-prefix entry (skip the tmux prefix)

You don't have to press the tmux prefix to reach the grouped verbs. The mechanism is tmux's `root` key-table (the `-n` flag = "no prefix"): bind one key there to switch into `tum-root`, and every grouped key from this document works unchanged. You've moved the **entry point**, not redesigned the keymap. Flip-flop (`H`) is already direct, so it is unaffected.

```sh
# Press F12 anywhere → you're in tum mode. No C-b needed.
#   F12  b        =  borrow              (two keystrokes)
#   F12  H 1      =  flip-flop slot 1    (H works here too, since it is also bound in tum-root)
bind-key -n F12 switch-client -T tum-root
```

The `<prefix> t` path and the no-prefix path can **coexist** — both reach the same `tum-root` table — so enable both and use whichever your hands are nearer. Set it from the source of truth:

```sh
set -g @tum-no-prefix-entry "F12"     # "" = disabled (default)
```

`tum bindings tmux` emits the extra `bind-key -n` line alongside the `<prefix> t` leader.

**The only real constraint is the key choice**, because `-n` bindings fire in *every* pane (shells, vim, emacs, pagers). The entry key must be something none of your apps use:

| Entry key              | Chain to borrow | Collision risk   | Notes                                                                                                    |
| ---                    | ---             | ---              | ---                                                                                                      |
| `<prefix> t` (default) | `C-b t b`       | none             | Recommended default; never interferes with apps                                                          |
| `F12`                  | `F12 b`         | very low         | Best no-prefix choice; F12 is rarely bound in terminal apps                                              |
| `Hyper-t` / `Super-t`  | `Hyper-t b`     | none             | Cleanest possible; needs a terminal with the kitty keyboard protocol (Kitty, iTerm2, Alacritty, WezTerm) |
| `C-Space`              | `C-Space b`     | low              | Usually free; some terminals send it as `C-@`/NUL — verify it reaches tmux                               |
| `M-t` (Alt+t)          | `M-t b`         | **high — avoid** | Collides with `transpose-words` in bash Readline and emacs, and with Meta usage in vim                   |

**Avoid two specific traps:**

- **`M-t`.** It's `transpose-words` in bash and emacs and is used by vim's Meta layer. It will bite you in any pane running a shell.
- **`C-\`.** It sends `SIGQUIT` to the foreground process — the kind of key that quietly kills your REPL or test runner.

### Modal vs. auto-return (a separate choice)

By default each leaf fires and returns you to `root`, so a second tum action needs another entry keystroke. If you chain several tum actions at once, switch to **sticky** entry mode: leaves fire but you stay in `tum-root` until `Esc`/`q`, so one entry gives you `t b` then `H 1` then `t x` in sequence without re-pressing the prefix. The tradeoff is the usual modal risk — a fumbled key leaves you "in tum mode" until you press `Esc`. Auto-return is the safer default; sticky is opt-in:

```sh
set -g @tum-entry-mode "sticky"     # "auto_return" (default) | "sticky"
```

The generated fragment differs only in whether leaves end with `switch-client -T root` (auto-return) or `switch-client -T tum-root` (sticky); the key assignments are identical either way.

---

## Memorization guide

If you remember nothing else, remember this:

> **`H` toggles (hide/show), per the requirements. `t` for tum, then: `b` borrow, `x` close, `p`/`P` push and pop, `i`/`I` import (anonymous/named). `u` is the universe (popup). The nouns you manage are `l` `g` `c` (Layout, Go/list, Config). `?` is help. Capital always means more: new, pop, named. `Esc`/`q` always cancels.**

A few mnemonic hooks that make the families stick:

- **`H` is the toggle.** The one key the requirements pin. It hides and shows by slot, or the focused pane, or via the chooser.
- **Three core verbs under `t`.** `b` `x` and the `H` toggle are the three things you do to a borrowed pane — bring it in, kill it, hide/show it.
- **Push and pop.** `p`/`P` are a pair: lowercase pushes (detaches), uppercase pops (attaches). One direction each.
- **Import.** `i`/`I` are a pair: lowercase is anonymous (temporary), uppercase is named (saved). Capital = more permanent.
- **`g` is "go look."** Everything read-only lives under `g`: ls, check, status.
- **When in doubt, `t u`.** The popup is the full menu; the shortcuts are just the fast lanes to it. If you forget a key, `t u` and `t ?` between them cover everything.

---

## Status and open decisions

This keymap is a proposed design, built on the requirements. A few items are deliberately left as decisions for the implementation phases:

| Open item                                                                           | Where it gets decided                                                     |
| ---                                                                                 | ---                                                                       |
| The `tum bindings tmux` generator and installer (keymap-proposed)                   | Phase 1 (CLI skeleton)                                                    |
| Flip-flop focused-toggle terminator: `Enter` vs. `.` vs. a direct-fire `H`          | Phase 0; this doc uses `Enter` in the sub-table                           |
| Whether `tum flip` and `tum close` are separate CLI commands or sub-flags of borrow | Phase 1 (CLI skeleton)                                                    |
| Whether `tum popup` and `tum cheatsheet` ship at all (keymap-proposed)              | Phase 1; the chooser + dedicated keys cover the requirements without them |
| Per-binding result feedback (`display-message` on `run-shell` actions)              | Phase 1                                                                   |
| Default `@tum-entry-mode`: `auto_return` (safer) vs. `sticky` (chains actions)      | Phase 0; this doc recommends `auto_return`                                |

The principle behind every open item is the same: the keymap must stay a thin wrapper over the CLI, generated from tmux options, never colliding with tmux, and always cancellable. As long as those hold, the exact key choices are tunable without redesign.
