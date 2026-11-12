---
title: tum-keymap
section: 5
header: tmux-borrow Manual
---

## NAME

tum-keymap \[em] the tum key-binding scheme and the shipped `tum-bindings.conf`

## SYNOPSIS

`source-file ~/.config/tmux/tum-bindings.conf`

## DESCRIPTION

A shortcut-driven way to drive every **tum**(1) command, grouped so it is
memorizable. The keymap is a thin layer over the CLI: every binding shells
out to the same `tum` commands scripts use, so the keymap and the CLI can
never drift apart. The bindings ship as a single static file,
`tum-bindings.conf`, that you source from your `tmux.conf`; to remap a key
you edit that file directly. There is no generator and no per-key option.

The design goals, in priority order:

1. **Fast for the daily loop.** Borrow, flip-flop, and close must be reflexes.
2. **Collision-free with tmux.** Nothing steals tmux's own prefix bindings.
3. **Memorizable.** Commands grouped under mnemonic leaders; uppercase = stronger variant; one mental map covers everything.
4. **Complete.** Every command is reachable from the keyboard.
5. **Configurable.** Every key is remappable; the bindings live in one editable file.

## THE CHAIN

There are two entry styles, and they coexist:

```
<prefix>  H  <slot>          ->  flip-flop (direct)
<prefix>  t  <key>           ->  the other verbs (grouped, collision-safe)
<prefix>  t  <group> <key>   ->  a family action
```

`<prefix>` is your normal tmux prefix (default `C-b`; many users remap to
`C-a` or `Space`). The keymap never assumes a particular prefix.

`H` enters the `tum-flip` sub-table directly from the prefix table. The
next key is a slot (`0`\[en]`9`, `a`\[en]`z`), or `Enter` (context-aware:
toggle the focused pane, or open the chooser when the host has several).

`t` enters the `tum-root` key-table. For leaves, the action fires and you
return to normal. For group leaders, you drop into a sub-table for one
more key.

The shortest path to the most common action is two keystrokes:

```
C-b   H   1      ->   flip-flop slot 1 (hide if shown, show if hidden)
```

Borrow is three:

```
C-b   t   b      ->   borrow (interactive chooser)
```

## DESIGN PRINCIPLES

These rules generate the whole keymap. Once you internalize them, you can
derive any binding without looking it up.

1. **Flip-flop is bound directly to `H`.** `H` (capital) is collision-safe
   \[em] tmux has no default `prefix H` binding \[em] so it lives directly
   in the prefix table.
2. **The `t` leader scopes the remaining verbs.** The natural mnemonic keys
   for the other verbs collide with tmux defaults (`x` = kill-pane,
   `p` = previous-window, `c` = new-window, `n` = next-window,
   `l` = last-window, `s` = choose-session). After your prefix, `t` enters
   "tum mode" and every subsequent key is read from tum's own key-tables,
   so none of these collide. `H` is the exception: it is safe, so it stays
   direct.
3. **Single key = common verb; `<group> <action>` = family.** The things
   you do constantly (borrow, close, push, pop, import) are single keys
   right after the leader. Everything that manages nouns (layout, list,
   config) is a two-key chord.
4. **Uppercase = stronger / broader variant.** `B` borrows new (vs `b`
   borrow existing-or-create); `P` pops (vs `p` push); `I` imports named
   (vs `i` anonymous). Capital always means "more."
5. **Mnemonics mirror the CLI verbs.** `b`orrow, `x` (close/kill),
   `p`ush, `i`mport, `l`ayout, `g`o (list), `c`onfig, `u` (popup, the
   universe).
6. **`Esc`/`q` always cancels, side-effect free.** From the leader, from
   any sub-group, or mid-prompt: cancel returns you to the root key-table
   with tmux state unchanged.

## MASTER SHORTCUT TABLE

Every binding, in one view. "Direct" = bound in the prefix table (no `t`
leader); "Leaf" = fires immediately after the leader; "Group" = opens a
sub-table for one more key; "Sub" = opens a sub-table that reads a slot.

| Key     | Type  | Action                                         | CLI                  |
| ---     | ---   | ---                                            | ---                  |
| `H`     | Sub   | Flip-flop (reads a slot) \[em] direct          | flip [<slot>]        |
| `t b`   | Leaf  | Borrow (no-name chooser)                       | borrow               |
| `t B`   | Leaf  | Borrow new (always create)                     | new                  |
| `t x`   | Leaf  | Close (context-aware kill-pane)                | close                |
| `t p`   | Leaf  | Push the focused borrowed pane onto the stack  | push                 |
| `t P`   | Leaf  | Pop the top of the stack to the current host   | pop                  |
| `t i`   | Leaf  | Import the current pane (anonymous, temporary) | import               |
| `t I`   | Leaf  | Import the current pane (named, saved to file) | import <name>        |
| `t u`   | Leaf  | Open the popup (master action menu)            | popup                |
| `t ?`   | Leaf  | Cheatsheet overlay                             | cheatsheet           |
| `t l`   | Group | Layout family                                  | \[em]                |
| `t g`   | Group | Go / view (listings)                           | \[em]                |
| `t c`   | Group | Config family                                  | \[em]                |
| `t q`   | Leaf  | Cancel (back to root)                          | \[em]                |
| `t Esc` | Leaf  | Cancel (back to root)                          | \[em]                |

## CORE VERBS (LEAVES)

These are the daily reflexes. They fire directly off `t` and return you to
the root table.

| Key   | Does         | What you see                                                                                                                      |
| ---   | ---          | ---                                                                                                                               |
| `t b` | Borrow       | Chooser over all utilities and layouts (no-name mode). Pick one -> pane attaches beside the active pane.                           |
| `t B` | Borrow new   | Same chooser, but always creates a fresh instance rather than reusing a hidden one (the `new` command). An owned instance \[em] flip-flop returns it only to this pane. |
| `t x` | Close        | Context-aware `kill-pane`: from a borrowed pane kills it; from a host with one, kills that; with several, opens the chooser.      |
| `t p` | Push         | Detaches the focused borrowed pane onto the LIFO push stack (no host). From the host with several borrowed, opens the chooser.    |
| `t P` | Pop          | Attaches the top pane of the push stack to the current host at its recorded geometry. Consumes it from the stack.               |
| `t i` | Import anon  | Tags the current pane as a temporary utility (`src=imported-anon`). No file written; behaves like any utility.            |
| `t I` | Import named | Prompts for a name, captures command/args/cwd/env from `/proc/$pid/`, writes a `<name>.util` file (`src=imported-named`). |
| `t u` | Popup        | The full interactive menu. Every command reachable with arrows/enter \[em] the catch-all for anything without a dedicated binding.    |
| `t ?` | Cheatsheet   | A popup listing every key in this page, grouped \[em] so you never have to leave tmux to remember.                                |

`t b` follows the default-mode resolution: an instance already bound to
this host is reused; else a hidden pool instance is borrowed (chooser if
several); else a fresh one is created. Close is immediate \[em] no
confirmation.

Worked example \[em] the core loop. You are editing in a project window
and want the app log beside you, then want it gone:

```
C-b t b          # chooser: pick "logs" -> the running tail pane appears beside your editor
# ...read, debug...
C-b H 1          # flip-flop slot 1 -> the log pane hides; editor untouched
# ...need it again...
C-b H 1          # flip-flop slot 1 -> the log pane shows again at its last geometry
```

The `tail` process never stopped. Hide is not close \[em] the pane is
alive in the hidden session, one keystroke away.

Worked example \[em] hand a utility to another session:

```
# in session a, focused on htop:
C-b t p          # htop pushed onto the stack; no host
# switch to session b (normal tmux):
C-b t P          # htop pops in beside the current pane at its recorded geometry
```

## FLIP-FLOP SUB-TABLE \[em] `H ...`

Every borrowed thing (a utility, a layout, or a layout member) gets a slot
key from the range `0`\[en]`9` or `a`\[en]`z`, declared in its definition
or auto-assigned on conflict. After `H`, you press one key:

| Key in `tum-flip` | Does                                                                               |
| ---               | ---                                                                                |
| `0`\[en]`9`, `a`\[en]`z`  | Toggle the thing in that slot. Hide if shown, show if hidden.                      |
| `Enter`           | Toggle the focused pane, or the host's single borrowed thing, or open the chooser for a host with several (context-aware no-slot case). |
| `q` / `Esc`       | Cancel; back to root, nothing changed.                                             |

Tmux needs a terminator key after entering a sub-table, so the
context-aware no-slot variant is realized as `<prefix> H Enter` here. A
layout's slot toggles all its members as a group; a member's slot toggles
just that member. Hiding a layout member parks it in the hidden session
but keeps its `lay` field; re-showing the layout brings it back.

## LAYOUT FAMILY \[em] `t l ...`

Borrowing a layout is covered by `t b`: the no-name chooser shows all
utilities **and** layouts, so picking a layout there borrows all its
members. The layout family itself is just file management.

| Key     | Does                                                        | What runs                                                                                       |
| ---     | ---                                                         | ---                                                                                             |
| `t l e` | Edit a layout's definition file (chooser picks which)       | chooser over `~/.config/tum/*.layout`, then `$EDITOR` opens the picked file                     |
| `t l l` | List the layout definition files                            | `ls ~/.config/tum/*.layout`                                                                     |
| `t l q` / `t l Esc` | Cancel                                          | \[em]                                                                                           |

These are keymap-level file operations, not `tum` subcommands: the binding
runs `$EDITOR` or `ls` directly.

## GO / VIEW FAMILY \[em] `t g ...`

Read-only listings. `g` for "go look."

| Key     | Does                                                     | CLI          |
| ---     | ---                                                      | ---          |
| `t g l` | List all utility panes across all sessions               | ls           |
| `t g c` | Check for orphans (host dead, utility alive)             | check        |
| `t g s` | Show the current pane's tum state (glyph + binding info) | status       |
| `t g q` / `t g Esc` | Cancel                                       | \[em]        |

## CONFIG FAMILY \[em] `t c ...`

The "config" is the set of definition files in `~/.config/tum/` plus the
`@tum-*` tmux options. There is no `tum config` command, so these bindings
run shell commands directly.

| Key     | Does                                                         | What runs                                  |
| ---     | ---                                                          | ---                                        |
| `t c e` | Open the config directory in `$EDITOR` (utilities + layouts) | `$EDITOR ~/.config/tum/`                   |
| `t c s` | Show effective `@tum-*` tmux options                         | `tmux show-options -g` (filtered to `@tum`) |
| `t c q` / `t c Esc` | Cancel                                          | \[em]                                      |

## POPUP AND HELP

| Key     | Does                                                                          |
| ---     | ---                                                                           |
| `t u`   | Popup \[em] the full interactive menu. Every command reachable with arrows/enter. |
| `t ?`   | Cheatsheet overlay \[em] every key in this page, grouped, in a popup.              |
| `t q`   | Cancel from the leader or any sub-group; back to root, nothing changed.       |
| `t Esc` | Same as `t q`.                                                                |

Cancel is a hard guarantee: whether you are at the leader, inside a
sub-table, or mid-prompt in a popup, `Esc`/`q` leaves tmux state exactly
as it was.

## THE BINDINGS FILE

Below is the shape of `tum-bindings.conf`. The shipped file is this,
validated; edit it in place to remap.

```sh
# tmux-borrow key bindings -- edit this file to remap keys.

# 1. Flip-flop: bound directly to H in the prefix table,
#    and again under the t leader so it works from either entry path.
bind-key -T prefix H switch-client -T tum-flip
bind-key -T tum-root H switch-client -T tum-flip

# 2. The leader: <prefix> t  ->  enter the tum-root key-table.
bind-key -T prefix t switch-client -T tum-root

# 3. Leaves fire and return to the root table.
#    Interactive bindings run in a popup (they need a TTY for the chooser);
#    non-interactive bindings use run-shell.
bind-key -T tum-root b \
    display-popup -E -w 80% -h 80% 'tum borrow' \;\
    switch-client -T root
bind-key -T tum-root B \
    display-popup -E -w 80% -h 80% 'tum new' \;\
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
    display-popup -E 'read -p "utility name: " name && tum import "$name"' \;\
    switch-client -T root
bind-key -T tum-root u \
    display-popup -E -w 80% -h 80% 'tum popup' \;\
    switch-client -T root
bind-key -T tum-root ? \
    display-popup -E 'tum cheatsheet' \;\
    switch-client -T root

# 4. Flip-flop sub-table: slot key, focused, chooser, cancel.
bind-key -T tum-flip Enter  run-shell -b 'tum flip'      \;  switch-client -T root
bind-key -T tum-flip 1      run-shell -b 'tum flip 1'    \;  switch-client -T root
bind-key -T tum-flip 2      run-shell -b 'tum flip 2'    \;  switch-client -T root
# ... one binding per slot key in use ...
bind-key -T tum-flip q      switch-client -T root
bind-key -T tum-flip Escape switch-client -T root

# 5. Group leaders drop into a sub-table for one more key.
bind-key -T tum-root l switch-client -T tum-layout
bind-key -T tum-root g switch-client -T tum-go
bind-key -T tum-root c switch-client -T tum-config

# 6. Sub-tables: layout, go, config.
bind-key -T tum-layout e display-popup -E 'tum-chooser "Edit layout" <(ls ~/.config/tum/*.layout) /tmp/tum.out && ${EDITOR:-vi} ~/.config/tum/$(basename "$(cat /tmp/tum.out)")' \; switch-client -T root
bind-key -T tum-layout l run-shell -b 'ls ~/.config/tum/*.layout' \; switch-client -T root
bind-key -T tum-layout q       switch-client -T root
bind-key -T tum-layout Escape  switch-client -T root

bind-key -T tum-go l run-shell -b 'tum ls'     \; switch-client -T root
bind-key -T tum-go c run-shell -b 'tum check'  \; switch-client -T root
bind-key -T tum-go s run-shell -b 'tum status' \; switch-client -T root
bind-key -T tum-go q       switch-client -T root
bind-key -T tum-go Escape  switch-client -T root

bind-key -T tum-config e run-shell -b '${EDITOR:-vi} ~/.config/tum/' \; switch-client -T root
bind-key -T tum-config s run-shell -b 'tmux show-options -g | command grep "@tum"' \; switch-client -T root
bind-key -T tum-config q       switch-client -T root
bind-key -T tum-config Escape  switch-client -T root

# 7. Cancel from the leader.
bind-key -T tum-root q       switch-client -T root
bind-key -T tum-root Escape  switch-client -T root
```

Two implementation notes worth knowing:

- **Popup vs. `run-shell`.** Any binding that opens the chooser or prompts
  needs a TTY, so it runs inside `display-popup -E`. Bindings that are
  genuinely non-interactive (push, pop, close-when-unambiguous) use
  `run-shell -b` and skip the popup.
- **Result feedback.** For silent `run-shell` bindings, the file can add a
  `display-message` on success/failure so a failed `t x` does not fail
  invisibly.

## NO-PREFIX ENTRY

You do not have to press the tmux prefix to reach the grouped verbs. The
mechanism is tmux's `root` key-table (the `-n` flag = "no prefix"): bind
one key there to switch into `tum-root`, and every grouped key works
unchanged.

```sh
# Press F12 anywhere -> you're in tum mode. No C-b needed.
bind-key -n F12 switch-client -T tum-root
```

The `<prefix> t` path and the no-prefix path can **coexist** \[em] both
reach the same `tum-root` table. The only real constraint is the key
choice, because `-n` bindings fire in *every* pane (shells, vim, emacs,
pagers).

| Entry key              | Chain to borrow | Collision risk   | Notes                                                                                                    |
| ---                    | ---             | ---              | ---                                                                                                      |
| `<prefix> t` (default) | `C-b t b`       | none             | Recommended default; never interferes with apps                                                          |
| `F12`                  | `F12 b`         | very low         | Best no-prefix choice; F12 is rarely bound in terminal apps                                              |
| `Hyper-t` / `Super-t`  | `Hyper-t b`     | none             | Cleanest possible; needs a terminal with the kitty keyboard protocol (Kitty, iTerm2, Alacritty, WezTerm) |
| `C-Space`              | `C-Space b`     | low              | Usually free; some terminals send it as `C-@`/NUL \[em] verify it reaches tmux                               |
| `M-t` (Alt+t)          | `M-t b`         | **high \[em] avoid** | Collides with `transpose-words` in bash Readline and emacs, and with Meta usage in vim                   |

Avoid two specific traps: `M-t` (it is `transpose-words` in bash and emacs
and is used by vim's Meta layer), and `C-\` (it sends `SIGQUIT` to the
foreground process).

### MODAL VS. AUTO-RETURN

The shipped file uses **auto-return**: each leaf fires and returns you to
`root`, so a second tum action needs another entry keystroke. This is the
safe default. If you chain several tum actions and want **sticky** entry
(leaves fire but you stay in `tum-root` until `Esc`/`q`), edit
`tum-bindings.conf`: change the trailing `switch-client -T root` on each
leaf to `switch-client -T tum-root`. The tradeoff is the usual modal risk
\[em] a fumbled key leaves you "in tum mode" until `Esc`.

## MEMORIZATION GUIDE

If you remember nothing else, remember this:

> **`H` toggles (hide/show). `t` for tum, then: `b` borrow, `x` close,
> `p`/`P` push and pop, `i`/`I` import (anonymous/named). `u` is the
> universe (popup). The nouns you manage are `l` `g` `c` (Layout, Go/list,
> Config). `?` is help. Capital always means more: new, pop, named.
> `Esc`/`q` always cancels.**

## COVERAGE \[em] EVERY COMMAND IS REACHABLE

| Command                  | Binding(s)                                        |
| ---                      | ---                                               |
| borrow (default mode)    | `t b` (chooser; default-mode resolution on pick)  |
| new                      | `t B`                                             |
| borrow (no-name chooser) | `t b`                                             |
| flip-flop by slot        | `H <slot>`                                        |
| flip-flop (context)      | `H Enter`                                         |
| close (context-aware)    | `t x`                                             |
| push                     | `t p`                                             |
| pop                      | `t P`                                             |
| import (anonymous)       | `t i`                                             |
| import <name>            | `t I`                                             |
| ls                       | `t g l`                                           |
| check                    | `t g c`                                           |
| status                   | `t g s`                                           |
| borrow a layout          | `t b` (chooser includes layouts)                  |
| edit a layout file       | `t l e`                                           |
| edit config dir          | `t c e`                                           |
| chooser (implicit)       | invoked inside commands when a choice is needed   |
| popup / cheatsheet       | `t u` / `t ?`                                     |

No command is unreachable; no binding duplicates another's job. The
chooser is implicit \[em] every binding that needs a choice invokes it
internally, so there is no `--interactive` flag to bind.

## SEE ALSO

**tum**(1), **tum-borrow**(1), **tum-flip**(1), **tum-close**(1),
**tum-popup**(1), **tum-cheatsheet**(1), **tum-defs**(5), **tmux**(1)
