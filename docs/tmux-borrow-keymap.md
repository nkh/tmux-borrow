# tmux-borrow — the vim-style keymap

## A shortcut-driven way to drive every `tum` command, grouped so it's memorizable.

> **Scope.** This document defines a proposed key-binding scheme for tmux-borrow: a tmux prefix → a `tum` leader → grouped, vim-style keys that reach every command in the CLI surface. It is built on top of the project's `200-improvements.md` backlog and the existing `commands/` and `user-guide/` specs. The keymap is a **superset** of the current interaction model, not a replacement of it — read "How this relates to the existing spec" below.

---

## Why a keymap at all

Typing `tum borrow --fzf` is fine for a script and fine for a command you run twice a day. It is not fine for the verb you hit forty times a session. The cost stacks: you reach for the prefix habit, then you type a word, then you pick from a list — when the *intent* ("bring my logs over here") is a single reflex. The interaction-design doc already names the right primitive — one popup (`tum popup`) that delegates to the same CLI commands scripts use — and the `200-improvements` backlog explicitly lists "one compact popup entry point" (#101), "fzf searchable selector" (#102), "make cancellation side-effect free" (#116), and "align popup actions with CLI" (#120) as goals.

This keymap extends that primitive the way vim extends the `:` command-line with leader keys: **the popup remains the single conceptual entry point, and the most-used actions also get direct, grouped shortcuts that call the exact same CLI commands underneath.** Nothing here is a parallel API. Every binding is `tum <command> <flags>` under the hood, so the scripting guide and the keymap can never drift apart.

The design goals, in priority order:

1. **Fast for the daily loop.** Borrow and return must be a reflex, not a sentence.
2. **Collision-free with tmux.** Nothing steals tmux's own prefix bindings.
3. **Memorizable, vim-style.** Commands grouped under mnemonic leaders; uppercase = stronger variant; one mental map covers everything.
4. **Complete.** Every command in `command-index.md` is reachable from the keyboard; anything not bound is one popup away.
5. **Configurable.** Every key is remappable; the bindings are generated from one config source of truth.

---

## How this relates to the existing spec

The interaction-design doc currently says: *"Keep tmux key bindings minimal: one configurable binding opens the popup. Do not bind every action separately."* That guidance was written to stop the tool from competing with tmux's own navigation, resize, zoom, and copy-mode keys — a real risk. This keymap preserves the *spirit* of that rule while relaxing its *letter*:

| Existing rule                                | This keymap's stance                                                                                                   |
| ---                                          | ---                                                                                                                    |
| One popup entry point (#101)                 | Kept. `t u` opens the full popup; it remains the single conceptual entry.                                              |
| Don't bind every action separately           | Relaxed for high-frequency verbs; rest in popup. Shortcuts under `t`, clear of tmux.                                   |
| Each action delegates to the same CLI (#120) | Kept and made literal — every binding shells out to `tum …`.                                                           |
| fzf primary, numbered fallback (#102, #104)  | Kept. fzf is the picker inside every interactive binding; numbered selection is the fallback.                          |
| Cancel is side-effect free (#116)            | Kept. `Esc`/`q` aborts from any point.                                                                                 |
| Collect prompts before mutation              | Kept. Prompting bindings run inside a popup with a TTY; nothing in tmux moves until all required values are collected. |

The net effect is the popup-plus-CLI design you already have, with a vim-style fast path layered on. If you only ever learn `t u`, you lose nothing; if you learn the leaders, the daily verbs collapse to three keystrokes.

---

## Design principles

These five rules generate the whole keymap. Once you internalize them, you can derive any binding without looking it up.

1. **The `t` leader scopes everything into tmux-borrow's namespace.** After your tmux prefix, `t` enters "tum mode." Every subsequent key is read from tum's own key-tables, so none of these bindings can collide with tmux's `b`/`c`/`n`/`s`/`w`/`0-9` defaults. This is the single decision that buys the rest of the design freedom.
2. **Single key = common verb; `<group> <action>` = family.** The five things you do constantly (`borrow`, `return`, `stop`, `run`, `popup`) are single keys right after the leader. Everything that manages nouns (`layout`, `define`, `config`) is a two-key chord: group leader, then action.
3. **Uppercase = stronger / broader variant.** Directly borrowed from vim (`w`/`W`, `e`/`E`): `b` borrows a pane, `B` borrows a whole window; `r` returns one, `R` returns all; `s` stops with confirmation, `S` force-stops; `l` lists concisely, `L` lists verbose. Capital always means "more."
4. **Mnemonics mirror the CLI verbs.** `b`orrow, `r`eturn, `s`top, `n`ew/run, `l`ayout, `d`efine, `c`onfig, `g`o (view/list), `a`ppearance, `D`octor, `i`nspect, `p`ane, `u` (popup, the universe). Where the CLI has a name, the key is its first letter.
5. **`Esc`/`q` always cancels, side-effect free.** From the leader, from any sub-group, or mid-prompt: cancel returns you to the root key-table with tmux state unchanged.

---

## The chain

```
<tmux-prefix>  →  t   →  <key>  (or  <group> <key>)
```

- **`<tmux-prefix>`** is your normal tmux prefix (default `C-b`; many users remap to `C-a` or `Space`). The keymap never assumes a particular prefix.
- **`t`** is the tmux-borrow leader — the "tum prefix" the user installs. It switches tmux into the `tum-root` key-table.
- **`<key>`** is then read from `tum-root`. For leaves, the action fires and you return to normal. For group leaders, you drop into a sub-table for one more key.

So the shortest path to the most common action is three keystrokes:

```
C-b   t   b      →   borrow (interactive)
```

That is the whole point: prefix + leader + one key, and the running pane slides over. The full chain for a less-common action is four keystrokes:

```
C-b   t   l   s   →   layout save (prompts for a name)
```

If you find the double prefix (`C-b` then `t`) too heavy, you can bind a **no-prefix entry key** (a key in tmux's `root` table) that drops you straight into `tum-root` — no tmux prefix at all. The whole grouped scheme is unchanged; you've just moved the entry point. See "No-prefix entry (skip the tmux prefix)" below; the short version is that `F12` is the safe choice and `M-t` is a footgun (it's `transpose-words` in bash and emacs).

---

## Master shortcut table

Every binding, in one view. "Leaf" = fires immediately after the leader; "Group" = opens a sub-table for one more key. **Improvements** cites the `200-improvements.md` IDs the binding directly satisfies.

| Key     | Type  | Action                                          | Equivalent CLI                 | Picker / prompts                            | Improvements                       |
| ---     | ---   | ---                                             | ---                            | ---                                         | ---                                |
| `t b`   | Leaf  | Borrow a pane (default mode)                    | `tum borrow --fzf`             | fzf over borrowable instances               | 21, 24, 34, 38, 102, 105, 106, 117 |
| `t B`   | Leaf  | Borrow a whole managed window                   | `tum borrow --fzf --as window` | fzf; window-mode                            | 33                                 |
| `t r`   | Leaf  | Return (active, or pick if ambiguous)           | `tum return --fzf`             | fzf over borrowed                           | 25, 26, 102                        |
| `t R`   | Leaf  | Return all borrowed (in scope)                  | `tum return --all --yes`       | none (batch)                                | 25, 115                            |
| `t s`   | Leaf  | Stop an instance (confirms)                     | `tum stop --fzf`               | fzf; confirm                                | 95, 134                            |
| `t S`   | Leaf  | Force-stop (graceful → force, no confirm)       | `tum stop --fzf --yes`         | fzf                                         | 96, 159                            |
| `t n`   | Leaf  | Run a registered utility                        | `tum run --fzf`                | fzf over definitions; prompts required args | 5, 14, 61                          |
| `t N`   | Leaf  | Run ad-hoc (`-- …`)                             | `tum run --adhoc`              | prompts name + command + opts               | 71                                 |
| `t i`   | Leaf  | Inspect an instance                             | `tum inspect --fzf`            | fzf → detail view                           | 10, 18, 19, 87, 112                |
| `t p`   | Leaf  | Borrow a pane from any session (incl. ordinary) | `tum borrow --select-pane`     | pane browser                                | 37, 38                             |
| `t u`   | Leaf  | Open the full popup (master entry)              | `tum popup`                    | popup menu                                  | 101, 107, 117, 120                 |
| `t ?`   | Leaf  | Cheatsheet overlay                              | `tum cheatsheet`               | popup                                       | 119                                |
| `t l`   | Group | Layout family                                   | —                              | —                                           | 41–60                              |
| `t d`   | Group | Define family                                   | —                              | —                                           | 1–20, 72–80                        |
| `t c`   | Group | Config family                                   | —                              | —                                           | 72–80                              |
| `t g`   | Group | Go / view (listings)                            | —                              | —                                           | 1, 2, 9, 10, 111, 114              |
| `t a`   | Group | Appearance (color)                              | —                              | —                                           | use-case 19, FR-025                |
| `t D`   | Group | Doctor / recovery                               | —                              | —                                           | 29, 125–140, 151                   |
| `t m`*  | Group | Quick-borrow (combinatorial: what/where)        | `tum quick-borrow`             | none                                        | 21, 24, 34                         |
| `t q`   | Leaf  | Cancel (back to root)                           | —                              | —                                           | 116                                |
| `t Esc` | Leaf  | Cancel (back to root)                           | —                              | —                                           | 116                                |

*\* `t m` is the quick-borrow leader. `m` is unbound in `tum-root`, so there is no conflict with the cheatsheet (`t ?`) or any other key. See "Quick borrow for common cases".*

> A note on verbs: the canonical command index uses `run`/`stop`/`popup`. Earlier drafts used `launch`/`kill`/`ui`. The bindings follow the canonical verbs; the popup (`t u`) keeps the `u` mnemonic from the earlier `ui` draft because it reads as "universe" (everything) and is already the key the example `tmux.conf` ships with.

---

## Family tables, with examples

Each family is a sub-table reached by its group leader. Within a family, the same rules apply: single key = action, uppercase = variant.

### Core verbs (leaves, no group)

These are the daily reflexes. They fire directly off `t` and return you to the root table.

| Key   | Does            | What you see                                                                                                                                 |
| ---   | ---             | ---                                                                                                                                          |
| `t b` | Borrow a pane   | fzf list of borrowable instances; pick one → the pane slides in beside the active pane. Required split args are prompted first.              |
| `t B` | Borrow a window | Same picker, but the chosen instance's *whole managed window* moves to your session (window-mode), pane and all.                             |
| `t r` | Return          | If one borrowed instance is tied to the active/host pane, it returns at once. Else an fzf list of borrowed instances; pick to return.        |
| `t R` | Return all      | Returns every manager-tracked borrowed resource in scope, no picker. Your ordinary panes are untouched.                                      |
| `t s` | Stop            | fzf over all instances; pick → confirm → stop. Never offers the host or an ordinary pane.                                                    |
| `t S` | Force stop      | fzf over instances; pick → graceful stop, then force if needed, no confirm.                                                                  |
| `t n` | Run registered  | fzf over definitions; pick → prompts for any required args → launches in its home window.                                                    |
| `t N` | Run ad-hoc      | Prompts for name, command, and options (`--cwd`, `--session`, `--on-exit`), then runs `tum run -- …`. Tracked like any instance.             |
| `t i` | Inspect         | fzf over instances; pick → detail view (definition, full ID, PID, state, home/current location, last borrow/return, exit status, host pane). |
| `t p` | Borrow any pane | Browser across *all* sessions/windows/panes, not just managed homes. Ordinary panes are flagged — no guaranteed automatic return home.       |
| `t u` | Popup           | The full interactive manager. Every command reachable with arrows/enter — the catch-all for anything without a dedicated binding.            |
| `t ?` | Cheatsheet      | A popup listing every key in this document, grouped — so you never have to leave tmux to remember.                                           |

**Worked example — the core loop.** You're editing in a project window and want the app log beside you, then want it gone:

```
C-b t b          # popup: pick "logs" → the running tail pane appears beside your editor
# …read, debug…
C-b t r          # the log pane returns to its home session; editor pane untouched
```

Three keystrokes in, three keystrokes out. The `tail` process never stopped.

**Worked example — clear the window before a meeting.** You borrowed three logs and a monitor; return them all at once:

```
C-b t R          # all four borrowed panes return home; your editor and shell stay put
```

### Layout family — `t l …`

Save, restore, and clone borrowed-only toolsets. Remember: a layout contains *only managed utility panes*; your editor and shell are never part of it.

| Key     | Does                                                                 | Equivalent CLI                       |
| ---     | ---                                                                  | ---                                  |
| `t l s` | Save current borrowed arrangement (prompts for a name)               | `tum layout save`                    |
| `t l r` | Restore a layout (fzf pick)                                          | `tum layout restore --fzf`           |
| `t l R` | Replace: return current borrowed set, then restore the picked layout | `tum layout restore --fzf --replace` |
| `t l l` | List layouts (sorted by recent use, with preview)                    | `tum layout list`                    |
| `t l e` | Edit a layout in `$EDITOR` (fzf pick)                                | `tum layout edit --fzf`              |
| `t l a` | Add a layout via the wizard                                          | `tum layout add --wizard`            |
| `t l c` | Clone a layout (pick source, prompt for destination name + args)     | `tum layout clone --fzf`             |

**Worked example — an incident room you replay.** A page comes in; you assemble a debugger and two logs from three different home sessions, then save the arrangement so the next 3 a.m. page is one keystroke:

```
# …borrow debugger, app-log, worker-log into your window…
C-b t l s        # prompt: name it "incident-room"
# …two weeks later, fresh incident, fresh window…
C-b t l r        # fzf: pick "incident-room" → all three panes assemble around your editor
```

**Worked example — swap toolsets without disturbing your editor.** Mid-task, a different fire lands; rotate the borrowed set, keep your work in place:

```
C-b t l R        # fzf: pick "other-fire" → current borrowed panes return, new set borrows in
```

### Define family — `t d …`

Manage utility definitions (the recipes). Definitions live in TOML; these bindings open the right file in `$EDITOR` for you.

| Key     | Does                                                                    | Equivalent CLI            |
| ---     | ---                                                                     | ---                       |
| `t d a` | Add a definition via the wizard (readline questions) or template append | `tum define add --wizard` |
| `t d e` | Edit a definition in `$EDITOR` (fzf pick)                               | `tum define edit --fzf`   |
| `t d r` | Remove a definition (checks for active instances first)                 | `tum define remove --fzf` |
| `t d l` | List definitions (grouped by category)                                  | `tum define list`         |
| `t d x` | Export a definition as TOML                                             | `tum define export --fzf` |

**Worked example — register `psql` with a required argument.** You want `psql` to prompt for a connection target every time:

```
C-b t d a        # wizard: name "psql", command "/usr/bin/psql",
                 #          required_args ["target"], exit_policy "wait"
# later, from any window:
C-b t n          # fzf: pick "psql" → prompt "Database / connection profile" → launches
```

### Config family — `t c …`

| Key     | Does                                                           | Equivalent CLI      |
| ---     | ---                                                            | ---                 |
| `t c e` | Open the main config in `$EDITOR`                              | `tum config edit`   |
| `t c s` | Show the effective merged config (defaults + definition + CLI) | `tum config show`   |
| `t c r` | Reload config (and run any migrations)                         | `tum config reload` |
| `t c n` | Run the one-time setup wizard                                  | `tum setup`         |

**Worked example — change the global exit policy.** You decide every utility should `wait` on exit instead of dropping to a shell:

```
C-b t c e        # opens config in $EDITOR → set [defaults] on_exit = "wait" → save
C-b t c r        # reload; new policy applies to the next launch
```

### Go / view family — `t g …`

Read-only listings. `g` for "go look." Uppercase `L` is the verbose/tree variant.

| Key     | Does                                                              | Equivalent CLI         |
| ---     | ---                                                               | ---                    |
| `t g l` | List instances (concise: ID suffix, definition, state, locations) | `tum list`             |
| `t g L` | List instances verbose / tree (sessions → windows → instances)    | `tum list --tree`      |
| `t g d` | List definitions (grouped by category)                            | `tum list definitions` |
| `t g s` | List home sessions the manager knows about                        | `tum list sessions`    |
| `t g p` | List panes (managed vs. ordinary distinguished)                   | `tum list panes`       |
| `t g t` | Tree view of sessions/windows/instances                           | `tum list --tree`      |

**Worked example — find what's borrowed where, fast.** Before a deploy you want to see everything currently out on loan:

```
C-b t g l        # concise table; scan the "state" column for "borrowed"
```

### Appearance family — `t a …`

Temporary color coding for borrowed panes. Color is restored automatically when the pane returns home (#25), so this is safe to set freely.

| Key     | Does                                                              | Equivalent CLI          |
| ---     | ---                                                               | ---                     |
| `t a s` | Set a borrowed pane's background (fzf instance, prompt for color) | `tum color set --fzf`   |
| `t a r` | Reset a pane's color (fzf instance)                               | `tum color reset --fzf` |

**Worked example — color-code your triage window.** Three logs borrowed in; give each a distinct background so your eye lands on the right one:

```
C-b t a s        # fzf: pick svc-auth   → prompt: "#1c1c1c"
C-b t a s        # fzf: pick svc-api    → prompt: "#263238"
C-b t a s        # fzf: pick svc-worker → prompt: "#37474f"
# …when each returns home, its color resets automatically
```

### Doctor / recovery family — `t D …`

`D` (capital, because diagnostics are "heavier") scopes into reconciliation and repair.

| Key     | Does                                                              | Equivalent CLI            |
| ---     | ---                                                               | ---                       |
| `t D d` | Run doctor: check deps + reconcile metadata vs. live tmux         | `tum doctor`              |
| `t D r` | Repair: reconcile interrupted ops, fix orphaned host associations | `tum doctor --repair`     |
| `t D o` | Open the manager state directory                                  | `tum doctor --open-state` |
| `t D s` | Read-only status / audit (no mutations)                           | `tum doctor --status`     |
| `t D e` | Export metadata for debugging                                     | `tum doctor --export`     |

**Worked example — recover after a laptop sleep mid-borrow.** You closed the lid while a borrow was in flight; on resume:

```
C-b t D d        # doctor reports: instance 8f31c2 in state "borrowing", pane verified live
C-b t D r        # repair completes (or rolls back) the half-done borrow; state → "home"
```

### Help and cancel

| Key     | Does                                                                    |
| ---     | ---                                                                     |
| `t ?`   | Cheatsheet overlay — every key in this doc, grouped, in a popup.        |
| `t q`   | Cancel from the leader or any sub-group; back to root, nothing changed. |
| `t Esc` | Same as `t q`.                                                          |

Cancel is a hard guarantee (#116): whether you're at the leader, inside a sub-table, or mid-prompt in a popup, `Esc`/`q` leaves tmux state exactly as it was. No half-moved panes, no partially-saved layout.

---

## Coverage audit — every command is reachable

The user's requirement was "do everything tum can do" from the keyboard. This table proves it: every command in `command-index.md` (plus the extra verbs from `user-guide.md`) maps to at least one binding. Anything not listed is one `t u` (popup) away.

| Command-index entry                            | Binding(s)                                                                                              |
| ---                                            | ---                                                                                                     |
| `list`                                         | `t g l` (instances), `t g d` (definitions), `t g s` (sessions), `t g p` (panes), `t g L`/`t g t` (tree) |
| `define add`                                   | `t d a`                                                                                                 |
| `define edit NAME`                             | `t d e`                                                                                                 |
| `define remove NAME`                           | `t d r`                                                                                                 |
| `run NAME`                                     | `t n`                                                                                                   |
| `run -- …` (ad-hoc)                            | `t N`                                                                                                   |
| `borrow`                                       | `t b` (pane), `t B` (window), `t p` (select-pane)                                                       |
| `return`                                       | `t r` (one), `t R` (all)                                                                                |
| `stop`                                         | `t s` (confirm), `t S` (force)                                                                          |
| `layout list`                                  | `t l l`                                                                                                 |
| `layout add`                                   | `t l a`                                                                                                 |
| `layout edit NAME`                             | `t l e`                                                                                                 |
| `layout save NAME`                             | `t l s`                                                                                                 |
| `layout restore NAME`                          | `t l r`, `t l R` (replace)                                                                              |
| `layout clone SRC DEST`                        | `t l c`                                                                                                 |
| `config edit`                                  | `t c e`                                                                                                 |
| `popup`                                        | `t u`                                                                                                   |
| `doctor`                                       | `t D d`                                                                                                 |
| *user-guide extras:* `inspect`                 | `t i`                                                                                                   |
| *user-guide extras:* `color set`/`reset`       | `t a s` / `t a r`                                                                                       |
| *user-guide extras:* `config show`             | `t c s`                                                                                                 |
| *user-guide extras:* `setup` wizard            | `t c n`                                                                                                 |
| *user-guide extras:* `layout replace`          | `t l R`                                                                                                 |
| *user-guide extras:* `borrow --select-pane`    | `t p`                                                                                                   |
| *backlog extras:* export metadata / definition | `t D e` / `t d x`                                                                                       |

No command is unreachable; no binding duplicates another's job.

---

## A full session, shortcuts only

To make the muscle memory concrete, here is a realistic afternoon driven entirely by the keymap — no `tum` typed at all.

```
# Morning: register a log viewer and start it
C-b t d a          # wizard → define "logs" = tail -F /var/log/syslog
C-b t n            # fzf → pick "logs" → running in its home window

# Switch to your project window (normal tmux), edit for a while...
# ...bug surfaces, you want the log beside the code:
C-b t b            # fzf → pick "logs" → pane slides in beside your editor
C-b t a s          # tint it "#263238" so it reads as "borrowed"

# A second service starts misbehaving; bring its log in too
C-b t n            # fzf → pick "svc-api" (or ad-hoc via t N) → starts + you borrow it
C-b t b            # fzf → pick "svc-api"

# Save this triage arrangement so a colleague can reproduce it
C-b t l s          # prompt → name "auth-triage"

# Meeting in two minutes; clear the window
C-b t R            # all borrowed panes return home; editor untouched

# After the meeting, the bug is back; one keystroke restores the room
C-b t l r          # fzf → pick "auth-triage" → both logs re-borrow in, same arrangement

# Done for real; clean up and check health
C-b t R            # return all
C-b t D d          # doctor: everything reconciled, no orphans
```

Every step is three or four keystrokes. No command typed, no menu navigated except where a picker is genuinely needed.

---

## Configuration

The keymap is generated from a single source of truth — tmux-borrow's own TOML config — so you configure keys once, and an installer emits the tmux `bind-key` block. You do not hand-maintain two files.

### tmux-borrow config (`config.toml`)

```toml
[ui]
selector = "fzf"            # "fzf" (default) or "numbered" fallback (#104, #191)
popup_width = "80%"         # popup geometry (#107)
popup_height = "80%"
cancel_key = "Escape"       # also accepts "q" (#116)
cheatsheet_key = "?"
confirm_stop = true         # t s asks; t S / --yes skips (#95)

[bindings]
leader = "t"                # the tum prefix, after your tmux prefix

# No-prefix entry (optional): a key bound in tmux's ROOT table, so you
# reach tum mode WITHOUT pressing the tmux prefix. Empty = disabled (the
# default, collision-free <prefix> t path). Set to a key like "F12" to
# enable. See "No-prefix entry" below before choosing a key — M-t is a
# known footgun. Both entry paths can coexist.
no_prefix_entry = ""        # e.g. "F12", "C-Space", "Hyper-t"

# Entry mode: "auto_return" (default) fires each leaf and drops you back
# to normal, so every tum action needs a fresh entry. "sticky" keeps you
# in tum-root after each leaf until you press Esc/q — handy for chaining
# several actions, riskier if you fumble a key. Auto-return is safer.
entry_mode = "auto_return"  # "auto_return" | "sticky"

# Leaves (single key after leader)
borrow = "b"
borrow_window = "B"
return = "r"
return_all = "R"
stop = "s"
stop_force = "S"
run = "n"
run_adhoc = "N"
inspect = "i"
select_pane = "p"
popup = "u"
cheatsheet = "?"

# Group leaders
layout = "l"
define = "d"
config = "c"
go = "g"
appearance = "a"
doctor = "D"

# Quick-borrow leader (m is unbound in tum-root — see "Quick borrow").
# Empty = disabled.
quick_borrow = "m"

# Any action omitted here keeps its default; any key left unbound
# falls through to the popup (t u). Rebinding is always non-destructive.

# Quick-borrow: combinatorial grammar t m [what][where] utility.
# Only the numbered utilities and the what/where defaults are configured
# here; fuzzy-letter, Tab, and F (fzf) modes resolve at runtime.
[quick-borrow]
leader        = "m"     # t m  ->  hand the rest to `tum quick-borrow`
default_what  = "pane"  # when 'what' (P/W) is omitted
default_where = "right" # pane: split right; window: after current

[quick-borrow.utilities]
1 = "files"
2 = "logs"
3 = "lazygit"
4 = { utility = "repl", preset = "project" }
```

### tmux config (`~/.tmux.conf`)

The recommended pattern: let `tum` generate the bindings from the TOML above, then source them. This keeps the keymap and the config in sync automatically (#165, #173).

```sh
# --- tmux-borrow: install the vim-style keymap from tum's config ---
# Generate the bind-key block into a fragment, then source it.
run-shell 'tum bindings tmux > ~/.config/tmux/tum-bindings.conf'
source-file ~/.config/tmux/tum-bindings.conf
```

If you prefer to see exactly what's installed, the generated fragment has this shape (illustrative; the real file is produced and validated by `tum bindings tmux`):

```sh
# Generated by `tum bindings tmux` — do not edit by hand; edit config.toml instead.

# 1. The leader: <prefix> t  →  enter the tum-root key-table.
bind-key -T prefix t switch-client -T tum-root

# 2. Leaves fire and return to the root table.
#    Interactive bindings run in a popup (they need a TTY for fzf/prompts);
#    the borrowed/returned pane lands in the originating window.
bind-key -T tum-root b \
    display-popup -E -w 80% -h 80% 'tum borrow --fzf' \;\
    switch-client -T root
bind-key -T tum-root B \
    display-popup -E -w 80% -h 80% 'tum borrow --fzf --as window' \;\
    switch-client -T root
bind-key -T tum-root r \
    display-popup -E -w 80% -h 80% 'tum return --fzf' \;\
    switch-client -T root
bind-key -T tum-root R \
    run-shell -b 'tum return --all --yes' \;\
    switch-client -T root
bind-key -T tum-root u \
    display-popup -E -w 80% -h 80% 'tum popup' \;\
    switch-client -T root

# 3. Group leaders drop into a sub-table for one more key.
bind-key -T tum-root l switch-client -T tum-layout
bind-key -T tum-root d switch-client -T tum-define
bind-key -T tum-root c switch-client -T tum-config
bind-key -T tum-root g switch-client -T tum-go
bind-key -T tum-root a switch-client -T tum-appearance
bind-key -T tum-root D switch-client -T tum-doctor

# 4. Cancel from the leader (and every sub-table has its own q/Esc → root).
bind-key -T tum-root q       switch-client -T root
bind-key -T tum-root Escape  switch-client -T root

# 5. One sub-table, shown in full (the others follow the same shape).
bind-key -T tum-layout s display-popup -E 'tum layout save' \; switch-client -T root
bind-key -T tum-layout r display-popup -E 'tum layout restore --fzf' \; switch-client -T root
bind-key -T tum-layout R display-popup -E 'tum layout restore --fzf --replace' \; switch-client -T root
bind-key -T tum-layout l display-popup -E 'tum layout list | less' \; switch-client -T root
bind-key -T tum-layout e display-popup -E 'tum layout edit --fzf' \; switch-client -T root
bind-key -T tum-layout a display-popup -E 'tum layout add --wizard' \; switch-client -T root
bind-key -T tum-layout c display-popup -E 'tum layout clone --fzf' \; switch-client -T root
bind-key -T tum-layout q       switch-client -T root
bind-key -T tum-layout Escape  switch-client -T root
```

**Two implementation notes worth knowing:**

- **Popup vs. `run-shell`.** Any binding that might prompt or show an fzf picker needs a TTY, so it runs inside `display-popup -E`. Bindings that are genuinely non-interactive (like `return --all --yes`) can use `run-shell -b` and skip the popup. The installer picks the right one per command; you don't choose.
- **Result feedback.** For silent `run-shell` bindings, the installer also emits a `display-message` on success/failure so a failed `t R` doesn't fail invisibly — you'll see "returned 3" or "nothing borrowed" in the status line.

### No-prefix entry (skip the tmux prefix)

You don't have to press the tmux prefix at all. The mechanism is tmux's `root` key-table (the `-n` flag = "no prefix"): bind one key there to switch into `tum-root`, and every grouped key from this document works unchanged. You've moved the **entry point**, not redesigned the keymap.

```sh
# Press F12 anywhere → you're in tum mode. No C-b needed.
#   F12  b    =  borrow        (two keystrokes)
#   F12  l s  =  layout save   (three keystrokes)
bind-key -n F12 switch-client -T tum-root
```

The `<prefix> t` path and the no-prefix path can **coexist** — both reach the same `tum-root` table — so enable both and use whichever your hands are nearer.

**The only real constraint is the key choice**, because `-n` bindings fire in *every* pane (shells, vim, emacs, fzf, pagers). The entry key must be something none of your apps use:

| Entry key              | Chain to borrow | Collision risk   | Notes                                                                                                    |
| ---                    | ---             | ---              | ---                                                                                                      |
| `<prefix> t` (default) | `C-b t b`       | none             | Recommended default; never interferes with apps                                                          |
| `F12`                  | `F12 b`         | very low         | Best no-prefix choice; F12 is rarely bound in terminal apps                                              |
| `Hyper-t` / `Super-t`  | `Hyper-t b`     | none             | Cleanest possible; needs a terminal with the kitty keyboard protocol (Kitty, iTerm2, Alacritty, WezTerm) |
| `C-Space`              | `C-Space b`     | low              | Usually free; some terminals send it as `C-@`/NUL — verify it reaches tmux                               |
| `M-t` (Alt+t)          | `M-t b`         | **high — avoid** | Collides with `transpose-words` in bash Readline and emacs, and with Meta usage in vim                   |

Set this from the config source of truth rather than hand-editing `tmux.conf`:

```toml
[bindings]
no_prefix_entry = "F12"     # "" = disabled (default); "F12" / "C-Space" / "Hyper-t" / …
```

`tum bindings tmux` then emits the extra `bind-key -n` line alongside the `<prefix> t` leader — both stay in sync from one config.

**Avoid two specific traps:**

- **`M-t`.** It's `transpose-words` in bash and emacs and is used by vim's Meta layer. It will bite you in any pane running a shell. The previous draft of this section used `M-t` as its example; don't.
- **`C-\`.** It sends `SIGQUIT` to the foreground process — the kind of key that quietly kills your REPL or test runner.

**Modal vs. auto-return (a separate choice).** By default each leaf fires and returns you to `root`, so a second tum action needs another entry keystroke (`F12 b`, then `F12 r`). If you chain several tum actions at once, switch to **sticky** entry mode: leaves fire but you stay in `tum-root` until `Esc`/`q`, so one entry gives you `F12 b r s` (borrow, return, stop) in sequence. The tradeoff is the usual modal risk — a fumbled key leaves you "in tum mode" until you press `Esc`. Auto-return is the safer default; sticky is opt-in:

```toml
[bindings]
entry_mode = "sticky"       # "auto_return" (default) | "sticky"
```

The generated tmux fragment differs only in whether leaves end with `switch-client -T root` (auto-return) or `switch-client -T tum-root` (sticky); the key assignments are identical either way.

### Optional: direct fast tier (promote the top verbs to the prefix)

Power users who don't rely on tmux's default `b`/`r` bindings can promote the two most common verbs straight to the prefix — no `t` leader — for a two-keystroke borrow:

```sh
# ONLY if you don't use tmux's default b/r bindings:
bind-key -T prefix b display-popup -E 'tum borrow --fzf' \; switch-client -T root
bind-key -T prefix r display-popup -E 'tum return --fzf' \; switch-client -T root
# Everything else stays under the t leader.
```

**Collision warning:** `b` is not a tmux default (safe), but `r`/`s`/`n` may be bound in some configs or plugins. The installer will refuse to promote a key that's already bound in your `prefix` table, and will report which key blocked it, rather than silently shadowing an existing binding.

### Quick borrow for common cases (nested key map, leader `m`)

`t b` opens the fzf picker over every borrowable instance — the right default for the general case, but a step you don't need for the two or three utilities you reach for all day. You already know which one you want; you just want it beside you, now. Quick-borrow is the fast path for that.

**The grammar.** Quick-borrow is a single combinatorial entry under one leader key, not a flat list of shortcuts. After `t m` you type a short sequence that picks three things in order — what to borrow into, where to put it, and which utility — and any part you omit takes a default:

```
t m  [what] [where] utility
      |      |      └─ 1-9 (numbered), letters (fuzzy), Tab (complete), F (fzf)
      |      └ l (left) | r (right) | ... (more directions)
      └─ P (pane), W (window)
```

- **what** — `P` borrows into a pane (a split of the current pane); `W` borrows into a window (a new window in the current session). Omitting it defaults to **pane** (from `t m 1` and `t m r`, which land in a pane).
- **where** — `l` places the new pane to the left (or, for a window, inserts it before the current one); `r` places it to the right (or after the current window). The `...` in the requirement leaves room for more directions (up/down, far-left/far-right). Omitting `where` defaults contextually: a pane splits to the right of the current pane; a window is inserted after the current window.
- **utility** — required; four ways to name it: a digit `1`–`9` for a user-configured shortcut; one or more letters for a fuzzy match on the utility name; `Tab` to complete from what you've typed; `F` to drop into the fzf picker over all utilities.

The `what` default is **pane**; the `where` default is **right** for a pane and **after the current window** for a window — both confirmed by the user.

**The examples.** All four resolve cleanly under the grammar with leader `m`. `t m Wr1` confirms the user's reading: the trailing `1` is the numbered utility, not a fuzzy letter.

| Input     | Parsed as                                  | Meaning                                                  |
| ---       | ---                                        | ---                                                      |
| `t m 1`   | utility 1; pane (default); right (default) | utility 1 in a pane on the right                         |
| `t m r`   | fuzzy `r`; pane (default); right (default) | utility whose name starts with r, in a pane on the right |
| `t m Prr` | `P` + `r` + utility `r`                    | utility starting with r, pane on the right               |
| `t m Wr1` | `W` + `r` + utility 1                      | utility 1 in a window after the current window           |


**Disambiguation (open).** Because `where` and `utility` can both be lowercase letters, the parser needs a rule for telling them apart. The examples imply: a lone trailing letter is the utility (so `t m r` is utility-r, with where defaulted); an extra letter after an explicit `what` is consumed as `where` first, the rest as utility (so `t m Prr` is P + right + utility-r). The consequence is that you can't express "where only, utility-by-a-where-letter" without writing both — to borrow a utility whose name starts with `l` into a left pane you must write `t m Pll` (`P` + `l`=left + `l`=utility), because `t m Pl` alone reads `l` as the utility. Whether that is acceptable, or the grammar should grow a separator, is a Phase 0 decision.

**Configuration.** Only the numbered utilities and the defaults are user-configured; the fuzzy, Tab, and F modes resolve against the registered utilities at runtime:

```toml
[quick-borrow]
leader          = "m"    # the t m group leader
default_what    = "pane" # when 'what' (P/W) is omitted
default_where   = "right"# pane: split right of current; window: after current

[quick-borrow.utilities]
# digit = utility (+ optional preset). The digit is what you type last.
1 = "files"
2 = "logs"
3 = "lazygit"
4 = { utility = "repl", preset = "project" }
```

**Implementation note.** The numbered and single-letter cases are fixed-length, but fuzzy letters are variable-length and `Tab`/`F` are interactive, so the sub-table can't be a flat set of static leaves. The realistic shape is two-stage: `t m` routes into a small `tum quick-borrow` helper (via `run-shell`) that reads the typed sequence and resolves it — applying the what/where defaults, matching the utility (numbered → config, letters → fuzzy, `Tab` → complete, `F` → fzf), then issuing `tum borrow` (or `tum run --borrow` if no instance exists yet). The pure-tmux key-table handles only the leader and the cancel keys; the combinatorics live in the helper. This keeps "quick" honest: `t m 1` and `t m r` still complete in one short sequence with no picker, while fuzzy and fzf remain available inside the same grammar for the cases a number can't cover.

```sh
# Quick-borrow leader: t m  ->  hand the rest of the sequence to the helper.
bind-key -T tum-root 'm' run-shell -b 'tum quick-borrow'

# Cancel stays in the key-table so it's instant.
bind-key -T tum-root q       switch-client -T root
bind-key -T tum-root Escape  switch-client -T root
```

**Leader: `m`.** The `?` in the requirement was a placeholder, and `?` is already the cheatsheet leaf. The user proposed `m` if free; it is — `m` is unbound in `tum-root` (bound root keys are `b B r R s S n N i p u ? q l d c g a D`), so there is no conflict and no other key needs to move. The mnemonic is loose: `m` for "mine"/"me" — bring this utility *to me*, beside the current pane. If a stronger mnemonic is wanted later, `m` can be reassigned with one config line, since quick-borrow is generated from `config.toml`.

**Relationship to the existing keys.** Quick-borrow does not replace anything; it layers on top:

- `t b` stays the general interactive borrow (fzf over all instances). Quick-borrow is a faster path *to* a named utility, with its own fuzzy/fzf fallbacks — not a replacement for the global picker.
- `t n` starts a new registered instance. Quick-borrow *borrows* an existing one, starting one only as a fallback. They compose: `t n` to create, `t m 1` to grab it fast thereafter.
- `t u` (popup) remains the catch-all for anything the grammar doesn't cover.

**Tradeoffs.** Quick-borrow is a power-user opt-in. Its cost is a configurable layer (the numbered utilities and defaults) plus a small helper to parse the sequence, and the usual risk that a chosen mnemonic collides with a future core binding. The installer mitigates collisions: it refuses a `[quick-borrow]` leader or utility digit already bound in `tum-root`. The benefit is collapsing the highest-frequency action — "borrow my file manager" — to three or four keystrokes with no picker (`t m 1`), while keeping fuzzy and fzf reachable inside the same grammar for the long tail.

---

## How this maps to the `200-improvements` base

The keymap was designed against the backlog. This table shows which improvements each part of the scheme satisfies, so the grounding is auditable.

| Backlog theme (IDs)                                                                               | Satisfied by                                                                   |
| ---                                                                                               | ---                                                                            |
| Popup; fzf; numbered fallback; cancel safe; align with CLI (101, 102, 104, 116, 120)              | `t u` popup; fzf pickers; `Esc`/`q` cancel; bindings delegate to CLI           |
| Borrow beside pane / across sessions / batch / preview / conflicts (21, 24, 34, 36, 38, 117)      | `t b` default; fzf multi-select batch; destination preview in picker           |
| Borrow complete window (33)                                                                       | `t B`                                                                          |
| Return active / return by host / return all (25, 26)                                              | `t r` (auto-resolves active/host), `t R`                                       |
| Confirm stop / never kill unknown / graceful→force (95, 134, 96, 159)                             | `t s` (confirm), `t S` (force); ownership proof blocks ordinary panes          |
| Start another instance / validate executable / required-arg prompts (5, 14, 61)                   | `t n`                                                                          |
| Ad-hoc supports manager options (71)                                                              | `t N`                                                                          |
| Inspect: locations, uptime, last borrow/return, exit status, copy ID (10, 18, 19, 87, 112)        | `t i`                                                                          |
| Save managed-only / arg policy / block secrets / prompts first / rollback (41, 48, 49, 55, 56)    | `t l s`, `t l r`                                                               |
| Clone for another project / reuse shared / per-window (44, 45, 46)                                | `t l c`                                                                        |
| Open config in editor / show effective merged / detect unknown keys / migrations (72, 76, 77, 78) | `t c e`, `t c s`, `t c r`                                                      |
| Wizard / template append / validate TOML (73, 74, 75)                                             | `t d a`, `t l a`                                                               |
| Group definitions by category / export TOML (9, 12)                                               | `t d l`, `t d x`                                                               |
| Tree view / concise+verbose listings (111, 114)                                                   | `t g t`, `t g l` / `t g L`                                                     |
| Temporary appearance restored on return (use-case 19, FR-025)                                     | `t a s`, `t a r`; auto-reset on return                                         |
| Doctor / reconcile / repair / orphans / audit / export (29, 125, 135, 136, 118, 151, 140)         | `t D d/r/o/s/e`                                                                |
| Help topic per command (119)                                                                      | `t ?` cheatsheet                                                               |
| Non-interactive mode (115)                                                                        | every binding passes `--yes` where the action is non-interactive (e.g. `t R`)  |
| Detect external pane moves / restore home placeholder (39, 40)                                    | handled by doctor (`t D d`), not a direct key — surfaced here                  |
| Keep tmux bindings minimal (108)                                                                  | respected in spirit: one leader, scoped sub-tables, no tmux-default collisions |

The improvements that are *not* direct keys (idle hooks, port/lock warnings, per-utility startup timeouts, etc.) are configuration and lifecycle concerns, surfaced through `t d e` (edit definition) and `t D d` (doctor) rather than their own bindings — which is the right call, since they're not reflexes.

---

## Memorization guide

If you remember nothing else, remember this:

> **`t` for tum. Then: the verbs are `b` `r` `s` `n` (Borrow, Return, Stop, New). `u` is the universe (popup). `i` is inspect, `p` is pane-browse. The nouns you manage are `l` `d` `c` (Layouts, Definitions, Config). `g` goes looking (lists). `a` is appearance. `D` is the Doctor. `?` is help. Capital always means more: window, all, force, verbose. `Esc`/`q` always cancels.**

A few mnemonic hooks that make the families stick:

- **Verbs first.** `b r s n` are the four things you *do* to a tool — bring it back, send it home, kill it, start a new one. They're the home row of the keymap.
- **Nouns second.** `l d c` are the three *things* you manage over time — layouts, definitions, config. You reach them less often, so they cost one extra key.
- **`g` is "go look."** Everything read-only lives under `g`: lists, sessions, panes, the tree.
- **Capital = bigger.** `b`→`B` (pane→window), `r`→`R` (one→all), `s`→`S` (confirm→force), `l`→`L` (concise→verbose). One rule, four variants.
- **When in doubt, `t u`.** The popup is the full menu; the shortcuts are just the fast lanes to it. If you forget a key, `t u` and `t ?` between them cover everything.

---

## Status and open decisions

This keymap is a proposed design, built on the existing specs and the `200-improvements` backlog. A few items are deliberately left as decisions for the implementation phases:

| Open item                                                                              | Where it gets decided                                                                   |
| ---                                                                                    | ---                                                                                     |
| Exact leader key default (`t` vs. another)                                             | Phase 0 (freeze decisions)                                                              |
| Ship a no-prefix entry by default? Which key (`F12` ok; `M-t` footgun)                 | Phase 0; recommends `<prefix> t` as default, no-prefix as opt-in                        |
| Default `entry_mode`: `auto_return` (safer) vs. `sticky` (chains actions, modal risk)  | Phase 0; this doc recommends `auto_return`                                              |
| Final verb names (`run`/`stop`/`popup` are canonical; `launch`/`kill`/`ui` are legacy) | Phase 1 (CLI skeleton); the keymap follows the canonical names                          |
| The `tum bindings tmux` generator and `tum bindings install`                           | Phase 9 (UI) or Phase 1 (skeleton), depending on whether bindings ship before the popup |
| Per-binding result feedback (`display-message` on `run-shell` actions)                 | Phase 9                                                                                 |
| Whether to ship the optional direct fast tier at all                                   | Phase 10 (lifecycle/release), gated on user testing                                     |
| Quick-borrow: finalize where-set (`l`/`r`/…) + letter disambiguation rule              | Phase 0; opt-in, see "Quick borrow"                                                     |

The principle behind every open item is the same: the keymap must stay a thin wrapper over the CLI, generated from one config, never colliding with tmux, and always cancellable. As long as those hold, the exact key choices are tunable without redesign.

