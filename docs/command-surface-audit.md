# tmux-borrow — command-surface audit

## What takes options, and how to shrink it

> **Scope.** This audit lists every command, flag, positional, tmux option, and definition key that makes up tmux-borrow's configuration surface, then proposes how to reduce it. The goal is the smallest surface that still meets the real use cases — fewer flags to parse, fewer options to document, fewer code paths to test. Reduction is approached three ways, as requested: dropping requirements that do not earn their complexity, splitting overloaded flags into dedicated commands, and factoring shared logic (target resolution, the chooser) out of the commands that repeat it.
>
> This document is a proposal record. Several reductions have since been adopted into the requirements: `on_exit` was dropped; `tum flip`, `tum close`, `tum popup`, `tum cheatsheet`, `tum bindings tmux`, and `tum prompt` were added as requirements-explicit commands; the layout DSL was unified to the flat, no-hierarchy form (no `members:` key); and `tum status`'s `--pane`/`--prompt` flags were split into `tum status [<pane_id>]` and `tum prompt`. Tables 1–3 below reflect the current requirements; the Reduction sections, the before/after comparison, and the proposed minimal surface record the original proposals and note which were adopted. Where a reduction has not been adopted (for example flip-flop's three variants), the conflict is called out and the decision is left to the implementation freeze.

---

## Table 1 — CLI commands and their options

`Source`: **req** = in `tmux-borrow-requirements.md`; **keymap** = proposed by the keymap doc only.

| Command                              | Options & arguments                                   | Source |
| ---                                  | ---                                                   | ---    |
| `tum borrow [<util or layout>]`      | `--new`, `--existing`, `--tag <tag>`, `--interactive` | req    |
| `tum flip [<slot>]`                  | `--interactive`                                       | req    |
| `tum close`                          | (none — context-aware)                                | req    |
| `tum push`                           | (none — acts on the focused borrowed pane)            | req    |
| `tum pop`                            | (none — attaches the top of the stack)                | req    |
| `tum import [<name>]`                | (none — name present = named; absent = anonymous)     | req    |
| `tum ls`                             | (none)                                                | req    |
| `tum check`                          | (none)                                                | req    |
| `tum status [<pane_id>]`             | (none — positional pane id for the status bar)        | req    |
| `tum prompt`                         | (none — PS1 glyph snippet)                            | req    |
| `tum popup`                          | (none)                                                | req    |
| `tum cheatsheet`                     | (none)                                                | req    |
| `tum bindings tmux`                  | (none — `tmux` selects the output format)             | req    |
| `tum-chooser <prompt> <items> <out>` | (none — fixed 3-positional contract)                  | req    |

The option load is not evenly distributed. `tum borrow` carries **4 of the 5 user-facing flags** in the whole CLI (`--new`, `--existing`, `--tag`, `--interactive`); `tum flip` carries the other 1 (`--interactive`). Every other command is flag-free — its behavior is positional or context-aware. So "reduce the options" almost entirely means "reduce `tum borrow` and the `@tum-*` option set."

---

## Table 2 — tmux `@tum-*` options (the config surface)

| Option                  | Default       | Source | Used by                            |
| ---                     | ---           | ---    | ---                                |
| `@tum-chooser`          | `tum-chooser` | req    | runtime — the chooser script path  |
| `@tum-host-glyph`       | `÷`           | req    | runtime — `tum status`             |
| `@tum-borrowed-glyph`   | `§`           | req    | runtime — `tum status`             |
| `@tum-hidden-session`   | `tum-hidden`  | req    | runtime — hidden/push session name |
| `@tum-leader`           | `t`           | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-no-prefix-entry`  | (empty)       | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-entry-mode`       | `auto_return` | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-key-borrow`       | `b`           | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-key-borrow-new`   | `B`           | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-key-close`        | `x`           | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-key-push`         | `p`           | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-key-pop`          | `P`           | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-key-import`       | `i`           | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-key-import-named` | `I`           | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-key-popup`        | `u`           | keymap | `tum bindings tmux` (keymap gen)   |
| `@tum-key-cheatsheet`   | `?`           | keymap | `tum bindings tmux` (keymap gen)   |

Twelve of the sixteen options exist only to drive `tum bindings tmux` (the keymap generator) — eight of them are the per-binding `@tum-key-*` remap knobs. The runtime reads only four. That separation matters for the reduction: the keymap-gen options can be cut without touching the runtime.

---

## Table 3 — definition-file keys (the per-utility/layout surface)

| File            | Key         | Required | Source | Notes                                                                           |
| ---             | ---         | ---      | ---    | ---                                                                             |
| `<name>.util`   | `command`   | yes      | req    | Executable path or name.                                                        |
| `<name>.util`   | `args`      | no       | req    | Arguments to the command.                                                       |
| `<name>.util`   | `cwd`       | no       | req    | Working directory.                                                              |
| `<name>.util`   | `env`       | no       | req    | Key=value pairs applied at launch.                                              |
| `<name>.util`   | `tags`      | no       | req    | Drives `--tag` and `@tum-tags`.                                                 |
| `<name>.util`   | `slot`      | no       | req    | Auto-assigned on conflict.                                                      |
| `<name>.layout` | `layout_id` | no       | req    | Defaults to the filename.                                                       |
| `<name>.layout` | (member)    | yes      | req    | A top-level `<member-name>: anchor=…, side=…, size=…` line; see the layout DSL. |

Two keys pull double duty as state: `tags` (also `@tum-tags` + the `--tag` flag) and `slot` (also `@tum-slot`). `on_exit` was dropped — closing a pane ends tmux-borrow's interest in it. Each droppable key removes a parser branch and, for `tags`, a state option and a CLI flag too.

---

## Where the complexity actually is

Counting the reducible surface:

- **CLI flags:** 5 total — 4 on `tum borrow` (`--new`, `--existing`, `--tag`, `--interactive`), 1 on `tum flip` (`--interactive`).
- **tmux options:** 16 total — 5 read by the runtime (incl. `@tum-hidden-session`), 11 read only by the keymap generator (8 of those are `@tum-key-*`).
- **definition keys:** 7 total — 6 utility keys, 1 layout key (`layout_id`); members are top-level lines, not a key.
- **`tum borrow` modes:** 5 (default, `--new`, `--existing`, `--tag`, no-name) × the resolution order (host-bound → hidden → create). This matrix is the single largest piece of logic in the spec.

The reductions below target exactly these. Nothing here touches the core model (pane-scope state, `kill-pane` close, the hidden session, push/pop LIFO) — only the option surface on top of it.

---

## Reduction 1 — split `tum borrow`'s flags into dedicated commands

`tum borrow` is overloaded: it carries a name selector, three mode flags, and a chooser flag. The mode flags are each a different verb and read better as commands. The chooser flag is redundant with the no-name mode.

| Current                    | Proposed            |
| ---                        | ---                 |
| `tum borrow --new <util>`  | `tum new <util>`    |
| `tum borrow --existing`    | (drop)              |
| `tum borrow --tag <tag>`   | (drop the flag)     |
| `tum borrow --interactive` | (drop — implicit)   |
| `tum borrow <util>`        | `tum borrow <util>` |
| `tum borrow` (no name)     | `tum borrow`        |

`tum new` accepts a layout name too (always creates fresh member instances), mirroring `tum borrow`. After this, `tum borrow` takes **zero flags** — only an optional positional. `tum new` is a sibling that reuses borrow's attach-to-host logic but skips the "reuse hidden instance" branch. Net: **−4 flags, +1 command**.

**On dropping `--existing`.** Its only effect is to refuse creation when no instance exists. The default mode already prefers existing instances (host-bound first, then hidden, create only as a last resort), so the common path never spuriously creates. The remaining case — "I want an error, not a new pane, if nothing is hidden" — is rare and recoverable (the user sees the new pane and closes it). If the need is later proven, restore it as `tum take <util>` (only-existing) rather than a flag, keeping the pattern consistent.

**On `--interactive`.** The requirements frame `--interactive` as "routes through the chooser," but every command already knows when it needs a choice (multiple hidden instances, several borrowed on a host). The flag's only real effect is forcing a chooser when one candidate exists — a niche confirmation. Make the chooser **implicit**: when a command must choose and a chooser is installed, it runs; otherwise a numbered list is printed. This removes `--interactive` from both `tum borrow` and `tum flip` and deletes the flag from the CLI entirely. The chooser *contract* (`tum-chooser <prompt> <items> <out>`) is unchanged — it becomes an internal call, not a user-facing flag.

---

## Reduction 2 — make `tum flip` context-aware (like `tum close`), merging two flip-flop variants

The requirements pin three flip-flop shortcuts: by slot (`<prefix> H <slot>`), focused (`<prefix> H`), and chooser (`<prefix> H` with `--interactive`). `tum close` is already context-aware — focused borrowed pane, host with one, or host with several (chooser) — and it carries no flag. `tum flip` can follow the same model:

| `tum flip` input     | Behavior                                                   | Replaces                                    |
| ---                  | ---                                                        | ---                                         |
| `tum flip <slot>`    | Toggle the thing in that slot.                             | `<prefix> H <slot>` (kept)                  |
| `tum flip` (no slot) | Focused borrowed → toggle it; host with several → chooser. | `<prefix> H` + the chooser variant (merged) |

The "focused" and "chooser" variants collapse into one no-argument call that resolves by context, exactly as `tum close` does. This **removes the `--interactive` flag from flip** and reduces the requirements' flip-flop table from three variants to two (by-slot, context). The keymap's `H <slot>` and `H Enter`/`H ?` both map to `tum flip`/`tum flip <slot>`; `H ?` becomes redundant with `H Enter` and can be dropped from the keymap. This is a requirements change (it merges two pinned shortcuts) and should be confirmed at the implementation freeze; the payoff is one shared "resolve the target pane" helper instead of three flip-flop paths.

---

## Reduction 3 — factor out the shared "resolve target pane" helper

`close`, `flip`, and `push`-from-host all answer the same question: *which borrowed pane does the user mean right now?* The resolution is identical:

1. Is the focused pane itself borrowed? → act on it.
2. Is the focused pane a host with exactly one borrowed thing? → act on that.
3. Is it a host with several? → open the chooser.
4. (None of the above → nothing to do, or error.)

Today this logic is described separately in the Close, Flip-flop, and Push sections. Factoring it into one internal helper — call it `tum-target` (a `tum-state` function, not a user command) — means `close`, `flip`, and `push` each become a thin wrapper: resolve the target, then do their one verb (kill / toggle / detach). The chooser call lives inside `tum-target`, so `--interactive` is never a flag the commands carry — it is an internal decision. This is the "factor out common components" reduction: three commands share one resolver instead of each re-implementing it.

`tum borrow` keeps its own resolver (host-bound → hidden → create) because it can *create*, which the others cannot; but its "pick among several hidden instances" step calls the same chooser.

---

## Reduction 4 — cut the keymap-generator options

Twelve of the sixteen `@tum-*` options exist only for `tum bindings tmux`. Eight of those are the per-binding `@tum-key-*` remap knobs. They can be cut without affecting the runtime:

| Option(s)                | Action                                   |
| ---                      | ---                                      |
| `@tum-key-*` (8 options) | Drop — edit the generated conf to remap. |
| `@tum-entry-mode`        | Drop — hardcode `auto_return`.           |
| `@tum-no-prefix-entry`   | Drop — document a manual `bind-key`.     |
| `@tum-leader`            | Keep.                                    |

The eight `@tum-key-*` options become unnecessary because the generated `tum-bindings.conf` is itself editable — one file to change a key, not eight options to learn. `@tum-entry-mode` is dropped because `auto_return` is the safe default and sticky mode is a niche chaining aid a user can build with a manual `bind-key`. `@tum-no-prefix-entry` is dropped because it is a footgun (the keymap says so) and belongs as a documented one-liner, not a first-class option. `@tum-leader` stays: the leader is the one binding users most want to change.

Result: the keymap-generator reads **1 option** (`@tum-leader`) instead of 12. The runtime's 4 mandated options (`@tum-chooser`, `@tum-host-glyph`, `@tum-borrowed-glyph`, `@tum-hidden-session`) are untouched. Total tmux options: **5, down from 16**.

---

## Reduction 5 — cut weak definition keys

| Key         | Action                                                                                             |
| ---         | ---                                                                                                |
| `on_exit`   | Dropped (adopted) — closing a pane ends tmux-borrow's interest; no exit policy.                    |
| `tags`      | Drop (or keep display-only).                                                                       |
| `layout_id` | Not adopted — requirements kept `layout_id` and dropped the `members:` wrapper instead (flat DSL). |
| `env`       | Keep (droppable if v1 must shrink).                                                                |
| `slot`      | Keep.                                                                                              |

**`on_exit`** is dropped (adopted): when the user closes a pane, it is gone and tmux-borrow does nothing further with it. There is no exit-policy key; a utility runs until the user closes it. **`tags`** is the highest-value cut — dropping it removes the `tags:` key, the `@tum-tags` state option, and the `--tag` flag in one move; the no-name chooser plus fzf filtering covers "borrow by category." If kept, it should be a `tum ls`/chooser display field only, with no `--tag` flag. **`layout_id`** was proposed for dropping (the filename is the natural id), but the requirements instead kept `layout_id` and dropped the `members:` wrapper, making the layout file flat — one `key:value` line per member, parsed by the same loop as utility files. **`env`** stays for cases like `PGPASSWORD` with `psql`; the flat `env: K=V,K=V` form is cheap to parse, but it is the next thing to cut if v1 must shrink further. **`slot`** stays — it is required for flip-flop and already optional with auto-assignment.

---

## Reduction 6 — collapse `tum status` integration flags (adopted)

`tum status`'s `--pane=<id>` (status bar) and `--prompt` (shell) were integration hooks, not user flags. Adopted: they are now two commands in the requirements.

| Before                   | After (in requirements)  |
| ---                      | ---                      |
| `tum status --pane=<id>` | `tum status [<pane_id>]` |
| `tum status --prompt`    | `tum prompt`             |

`tum status [<pane_id>]` takes a positional pane id (tmux interpolates `#{pane_id}` into it) and emits the glyph string for the status bar. `tum prompt` is a separate, flag-free command for the PS1 snippet — distinct output, distinct command.

---

## The proposed minimal surface

After all six reductions:

**CLI** (everything is positional or flag-free):

| Command                              | Options & arguments        |
| ---                                  | ---                        |
| `tum borrow [<util or layout>]`      | (none — no-name = chooser) |
| `tum new [<util or layout>]`         | (none — always create)     |
| `tum flip [<slot>]`                  | (none — context-aware)     |
| `tum close`                          | (none — context-aware)     |
| `tum push`                           | (none)                     |
| `tum pop`                            | (none)                     |
| `tum import [<name>]`                | (none)                     |
| `tum ls`                             | (none)                     |
| `tum check`                          | (none)                     |
| `tum status [<pane_id>]`             | (none)                     |
| `tum prompt`                         | (none — PS1 glyphs)        |
| `tum bindings tmux`                  | (none)                     |
| `tum popup`, `tum cheatsheet`        | (none — optional)          |
| `tum-chooser <prompt> <items> <out>` | (none — fixed contract)    |

**User-facing CLI flags: zero.** Every behavior is a command, a positional, or context. (`tum popup` and `tum cheatsheet` remain optional/deferrable; they carry no flags either way.)

**tmux options: 5** (down from 16) — `@tum-chooser`, `@tum-host-glyph`, `@tum-borrowed-glyph`, `@tum-hidden-session`, `@tum-leader`.

**definition keys: 6** (down from 9) — utility: `command`, `args`, `cwd`, `env`, `slot` (drop `on_exit`, drop `tags`); layout: `members` (drop `layout_id`).

**Internal factoring:** one `tum-target` resolver shared by `close`, `flip`, `push`-from-host; the chooser called implicitly inside it (no `--interactive` flag).

**Adoption status.** This is the full-proposal end state, not the current requirements. Of it, the requirements adopted: dropping `on_exit`; adding `tum flip`/`close`/`popup`/`cheatsheet`/`bindings`/`prompt`; splitting `tum status`/`tum prompt`; and the flat layout DSL — which dropped the `members:` wrapper and kept `layout_id`, the opposite of the `layout: members (drop layout_id)` row above. Not adopted: zero CLI flags (the requirements retain `--new`/`--existing`/`--tag`/`--interactive`), dropping `tags`, merging flip-flop to two variants, and cutting the `@tum-key-*` options. See the scope note.

---

## Before / after

| Surface                 | Before | After | Cut                                                                                    |
| ---                     | ---    | ---   | ---                                                                                    |
| CLI user-facing flags   | 6      | 0     | `--new`→`tum new`; drop `--existing`, `--tag`, `--interactive`×2, `--pane`, `--prompt` |
| `tum` subcommands       | 12     | 14    | +`tum new`, +`tum prompt` (commands replace flags)                                     |
| tmux `@tum-*` options   | 16     | 5     | drop 8×`@tum-key-*`, `@tum-entry-mode`, `@tum-no-prefix-entry`                         |
| utility definition keys | 7      | 5     | drop `on_exit`, `tags`                                                                 |
| layout definition keys  | 2      | 1     | drop `layout_id`                                                                       |
| flip-flop variants      | 3      | 2     | merge focused + chooser into one context-aware call                                    |
| borrow modes            | 5      | 3     | default, new (command), no-name; drop existing, tag                                    |

The flag count goes to zero by converting flags to commands or to implicit/context behavior. The option count drops by two-thirds. The definition keys drop by a third. The core model — pane-scope state, `kill-pane` close, the hidden session, push/pop, layouts — is unchanged.

---

## What this costs (the trade-offs to confirm)

Each reduction removes a capability. They should be confirmed at the implementation freeze, not silently applied:

- **Drop `--existing`:** loses "error if no instance exists." Recoverable later as `tum take`.
- **Drop `--tag` (and possibly `tags`):** loses borrow-by-category. The chooser's fuzzy filter covers most of it; power users lose a one-step shortcut.
- **Drop `--interactive`:** loses "force the chooser when one candidate exists." Commands auto-choose instead. The chooser contract is unchanged.
- **Merge flip-flop variants:** changes a requirements pin (three shortcuts → two). The chooser variant becomes the automatic behavior of the no-slot call.
- **Drop `on_exit` (adopted):** loses `shell`/`close`/`leave` exit behaviors. There is no exit-policy key; a utility runs until the user closes it.
- **Drop `layout_id` (not adopted):** the requirements instead kept `layout_id` and dropped the `members:` wrapper for a flat DSL. The filename remains the default id.
- **Drop the `@tum-key-*` options:** users edit the generated `tum-bindings.conf` to remap, instead of setting options. One file, not eight options.
- **Drop `@tum-entry-mode` / `@tum-no-prefix-entry`:** sticky mode and the no-prefix entry become manual `bind-key` lines in `tmux.conf`, not first-class options.

None of these touches the runtime's four mandated options or the core state model. If any cut proves too aggressive in practice, the pattern for restoring it is uniform: a dedicated command (`tum take`, `tum tag`) rather than a flag, so the CLI stays flag-free.

---

## Side note — doc inconsistencies found while auditing (resolved)

While cataloging, two inconsistencies between the docs surfaced. Both have since been reconciled:

- **Layout DSL format.** The requirements now specify a flat, no-hierarchy form: each member is a top-level `<member-name>: anchor=..., side=..., size=...` line, with no `members:` wrapper. The user-guide example was aligned to match. One `while IFS=: read` loop parses the whole file.
- **`tum config edit` / `tum config show`.** These were never in the requirements; the user-guide now uses `$EDITOR ~/.config/tum/` directly, matching the keymap's treatment.

These were documentation drift, not surface changes; both are now reconciled.
