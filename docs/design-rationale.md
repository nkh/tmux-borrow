# tmux-borrow — design rationale

> **Scope.** This document carries the *why* behind tmux-borrow's design — the
> reasoning that is not already captured in `tmux-borrow-requirements.md` (the
> spec, which states the *what*) or `implementation-roadmap.md` (the build
> plan). It consolidates five earlier design-process docs (component analysis,
> command-surface audit, tmuxake reuse analysis, plugin analysis, and use
> cases) into the parts that still inform the design. Anything here that
> became a decision is stated authoritatively in the spec; this is the
> lineage, the alternatives weighed, and the validation scenarios.

tmux-borrow is a small Bash orchestration layer over tmux. It keeps all
dynamic state in a tmux pane attribute (no external database), borrows
utility panes beside a host pane, toggles them with slot keys, closes them
with `kill-pane`, and composes working sets with push/pop and import. The
runtime is Bash-only (Perl acceptable for short helpers; no Python in
runtime code). Every project cited below was verified against its real
repository; URLs and licenses are taken from the projects themselves.

---

## Design lineage — from tmuxake

tmux-borrow is a superset of tmuxake (a single ~1340-line bash script by
Nadim Khemir that manages "side-panes"). tmux-borrow takes tmuxake's
hide/show/close flow and generalizes it to named utilities, layouts,
multiple instances, import, push/pop, and a pluggable chooser. **No code is
lifted from tmuxake** — only ideas, reimplemented in tmux-borrow's own
codebase.

tmuxake's core flow: a side-pane is an ordinary tmux pane bound one-to-one
to a host. When hidden it is `move-pane`'d into a hidden session, and that
window's *name* encodes the whole relationship. The window list of the
hidden session is the entire state — no database, no config file, no marker
on the pane.

### Ideas adopted

| tmuxake idea | How tmux-borrow uses it |
| --- | --- |
| State in tmux, no database | All dynamic state as a structured `tum:`-prefixed string in each utility pane's **pane title** (Alternative A, chosen by the viability test). Static config in `@tum-*` options. No sqlite, no index. The hidden session's pane list is the complete state. |
| Name-as-state | tmuxake encodes state in the hidden window's name; tmux-borrow encodes it in a pane attribute instead. Same principle (state rides on a tmux attribute that survives moves), applied at pane scope so each utility pane carries its own state everywhere it goes. |
| One shared hidden session | A single configurable session parks hidden and pushed panes. Any session can borrow from it. |
| Toggle (create/show/hide) | Borrow does this: hidden instance bound to this host, else existing hidden, else create. Flip-flop toggles by slot key. |
| Close from side or host | Close is context-aware: from a borrowed pane closes it; from a host with one borrowed closes it; with several, the chooser picks. |
| Close is just `kill-pane` | No teardown, no cleanup. State dies with the pane. |
| Geometry memory | Width and height are captured at hide and push (`geom` field) and restored on show and pop. |
| Status glyphs | `÷` for a host with borrowed things, `§` for a borrowed pane, `!` for an orphan. Configurable, tmuxake-like defaults. |
| Orphan detection | No proactive hooks. A dead host leaves the utility marked `!` until re-borrow or close. `tum check` lists orphans. Full-dead panes auto-removed. |
| Import | Adopt an existing pane as a utility. tmux-borrow adds a named variant that captures command/args/cwd/env to a definition file. |
| Push / pop | LIFO stack for cross-session hand-off, extended to multi-slot (non-contiguous seqs, since panes may be closed between pushes). |

### Ideas extended

| tmuxake concept | tmux-borrow extension |
| --- | --- |
| One side-pane per root pane | Multiple utilities and multiple layouts may attach to one host simultaneously. |
| A side-pane is always a shell | A utility is any named command with a definition file. |
| No grouping | Layouts group utilities; borrowing a layout borrows all members; members anchor to the host or to each other. |
| One instance per root | Multiple instances of one utility are allowed. `borrow` reuses (else creates); `new` always creates. |
| Window name encodes state | tmux-borrow uses a pane attribute instead — the state rides on the utility pane itself, not on its parking window. |
| PID-based identity | Pane id (`%N`) for binding — stable, never reused, no `kill -0`. PID read ephemerally at import only. |
| Single toggle key | Slot keys: every borrowed thing gets a slot for individual or group flip-flop. |
| `push`/`pop` one slot | LIFO stack of multiple panes; pop attaches at recorded geometry. |

### Ideas skipped

| tmuxake idea | Why skipped |
| --- | --- |
| PID as the binding key | PIDs recycle; pane ids are monotonic and never reused. Pane id is strictly better for binding and orphan detection. |
| `kill -0` orphan detection | With pane id, the check is "stored pane id in `list-panes -a`?" — no process probing, no PID-recycling risk. |
| Env via `show-env` + `send-keys` | Fragile (tmuxake spells out keys to dodge quoting). tmux-borrow sets env at launch through its tmux wrapper. |
| Window-name-as-state (literally) | The name-as-state *principle* is kept but moved to a utility pane *attribute* so each utility carries its own state everywhere it goes. |

### Architecture lessons

tmuxake's architecture is the opposite of a database-backed manager, and
the contrast is the lesson tmux-borrow takes to heart: **state in tmux, not
beside it.** The hidden session's pane list is the database. Nothing to
corrupt, nothing to reconcile after a crash, nothing to clean up on death
— the pane attribute dies with the pane, so full-dead cleanup is automatic.
tmuxake also leans heavily on tmux format interpolations (`#{pane_pid}`,
`#{pane_id}`, `#{pane_current_path}`, `#{pane_title}`), which are the right
tmux-native primitives; tmux-borrow uses the same ones through its `tum-tmux`
function group. And tmuxake needs only tmux and bash; tmux-borrow keeps the
core dependency-free, with the chooser as an external script (fzf is one
implementation, not a dependency of the core).

---

## State-store decision (R1) — Alternative A (pane title)

All dynamic per-pane state lives in a tmux pane attribute as a structured
`tum:`-prefixed string. All static configuration lives in `@tum-*` tmux
options. **No external database is used.**

Why a pane attribute and not a database: every piece of tmux-borrow state
is keyed to a specific pane (slot assignments, borrowed-set membership,
import metadata), so storing it in a pane attribute keeps it automatically
garbage-collected by `kill-pane`. sqlite, a JSON file, or a state daemon
would each add a runtime dependency, a second source of truth that can
drift from tmux's reality, and a cleanup problem when panes die. The
contrast with tmux-resurrect is informative: resurrect needs
cross-restart durability so it persists to plain-text files; tmux-borrow
needs live, in-band, pane-attached state so it uses a pane attribute.
Different need, different (correct) choice.

Two candidate attributes carry the dynamic string; both are pane attributes
that travel with the pane across `move-pane`/`join-pane` (including across
sessions):

- **Alternative A — the pane title** (`select-pane -T` / `#{pane_title}`).
  Has existed since tmux 1.x. Risk: terminal programs (`htop`, `vim`,
  `less`, `lazygit`, most curses apps) set the title themselves through
  escape sequences and would overwrite the `tum:` string. There is no
  per-pane option that prevents this.
- **Alternative B — a pane-scope `@tum-state` user option**
  (`set-option -p` / `show-options -p`). Introduced in tmux 3.0; safe from
  curses applications (programs cannot overwrite tmux user options);
  slightly more verbose. The project already requires tmux ≥ 3.2, so B is
  available.

**Chosen: Alternative A**, by the viability test (`make viability`, run
with tmux 3.5a). `htop`, `vim`, `less`, `tail`, and `bash` all preserved a
set title (`tum:probe=1`) through a refresh cycle; `man` uses `less` as its
pager (which preserved), so it is covered transitively. No tested target
utility clobbered the title, so A is viable and is chosen for its
simplicity. The choice is isolated behind one `tum-state` function group:
if a real-world target later clobbers (the failure mode is silent state
loss), switch to B there and nowhere else.

---

## Related work

An architectural comparison, not a dependency recommendation. Use native
tmux commands through the `tum-tmux` function group; do not inherit another
project's assumptions without reviewing its current source, license,
dependencies, and maintenance status. **No listed project is a runtime
dependency.**

| Project | Useful capability | Gap | Suggested use |
| --- | --- | --- | --- |
| tmuxake | Utility/side-pane management ideas | One-extra-pane limitation | Inspect selected ideas only |
| tmux-sessionist | Pane/window movement between sessions | No registry, instance model, prompts, or layouts | Study command patterns |
| tmux-resurrect | Save/restore sessions, windows, panes | Broad tmux state, not borrowed-only resources | Persistence reference only |
| tmux-continuum | Periodic resurrect saves | Not a utility manager | Not required |
| fzf-pane-switch.tmux | fzf pane selection | Selection only, no lifecycle | Optional UI reference |
| tmux-fzf-jump | fzf navigation across tmux objects | Navigation, not ownership/lifecycle | Optional UI reference |

- **tmuxake** (https://github.com/nkh/tmuxake) — conceptually close, but it
  handles only one extra pane and is not the foundation. Source of ideas
  only; see the lineage section above.
- **tmux-sessionist** (https://github.com/tmux-plugins/tmux-sessionist) —
  practical pane/window movement patterns, but no definitions, stable
  instance identity, argument collection, borrowed-only layouts, or crash
  reconciliation.
- **tmux-resurrect / continuum**
  (https://github.com/tmux-plugins/tmux-resurrect,
  https://github.com/tmux-plugins/tmux-continuum) — broad session
  persistence. The manager's layouts must contain only its own panes and
  must not overwrite ordinary user panes. Learn from serialization/recovery
  patterns, but do not require either plugin.
- **fzf selectors** (https://github.com/Kristijan/fzf-pane-switch.tmux,
  https://github.com/cengebretson/tmux-fzf-jump) — references for listing
  tmux objects and fzf interaction. They do not solve utility ownership or
  lifecycle. Keep fzf optional.

---

## Component-reuse choices

tmux-borrow is small, Bash-only, and stores state in tmux itself. The
reusable projects that fit are the ones with no runtime language dependency
(fzf, gum, bats, shellcheck, shfmt) or that are already part of tmux
(`display-popup`, `#(...)` interpolation, pane attributes). Everything else
is a few dozen lines of Bash.

| # | Component | Recommendation |
| --- | --- | --- |
| 1 | Interactive picker (chooser) | **fzf** as the reference `tum-chooser`; **skim** as a Rust-binary alternative. |
| 2 | Config file parsing | **Plain `bash read`** in a `while IFS=: read -r key value` loop. No library. |
| 3 | Structured input prompts | **gum** (`gum input`/`gum choose`); **Inquirer.sh** for zero-dependency. Not a snippet manager. |
| 4 | Popup / overlay rendering | **tmux `display-popup`** (tmux ≥ 3.2). No alternative needed. |
| 5 | tmux interaction (`tum-tmux`) | **Write it in Bash.** `libtmux` is the design reference but is Python (disqualified at runtime). |
| 6 | Process info capture (import) | Read **`/proc/$pid/{cmdline,cwd,environ}`** directly (split on NUL with `tr`). `ps`/`pstree` only locate the pid. |
| 7 | State storage (`tum-state`) | **The pane title** (Alternative A) for dynamic state; `@tum-*` options for static config. No external DB. |
| 8 | Bash completion | Write against the **bash-completion** API (`_init_completion`), with a hand-rolled `complete -F` fallback. |
| 9 | Status bar / prompt glyphs | tmux **`#(tum status …)`** interpolation + a sourced **Bash snippet**; optional **starship**/**p10k** segments. |
| 10 | Testing | **bats-core** against `tmux -L tum-test -f /dev/null`; **shellcheck** and **shfmt** as CI gates. |
| 11 | Packaging / distribution | **`make install`** baseline + a **Homebrew formula** + an **Arch AUR** `PKGBUILD`; document git-clone-and-symlink. |

The key picks, with the reasoning that is not obvious from the table:

- **fzf** matches the chooser contract exactly (`tum-chooser <prompt>
  <items_file> <output_file>` — reads items from a file, writes the
  selection to a file, exits 0 on selection or non-zero on cancel) and
  ships with tmux popup support. A user who prefers Rust can point
  `@tum-chooser` at a skim wrapper; nothing else changes. The chooser is
  external and implicit — invoked inside commands when a choice is needed,
  so no command carries an `--interactive` flag. With no chooser installed,
  commands fall back to erroring or a numbered list.
- **Plain `bash read`** is the whole definition parser: definitions are
  flat `key:value`, no sections, no hierarchy, no quoting, so one `read`
  loop per file is all there is. A dedicated parser (crudini, TOML/YAML
  CLI) would add a runtime dependency for zero benefit.
- **gum** for structured prompts (a utility launching without its required
  args, or named-import capturing name/command/cwd/env), with Inquirer.sh
  as the zero-dependency fallback. A snippet/bookmark manager (`pet`,
  `buku`) is the wrong abstraction — it imposes its own data model rather
  than letting tmux-borrow prompt for the fields it needs.
- **`display-popup`** (tmux ≥ 3.2) is the chooser/prompt overlay. Its
  stdin/stdout are the popup's own pane, not the caller's, so tmux-borrow
  bridges data through temp files — exactly the chooser-contract
  file-bridge. The binding constraint on the tmux version is `display-popup`,
  not state storage.
- **`/proc/$pid/`** is the highest-fidelity source for named import
  (`cmdline`/`cwd`/`environ`, read with `tr '\0' '\n'` / `readlink`). No
  standard CLI tool reassembles a re-runnable command line from the
  NUL-separated data — that is the small Bash/Perl helper tmux-borrow
  writes itself. PID is read ephemerally at import only; it is never stored
  as a binding key.

### What is deliberately not reused

- **libtmux / tmuxp / tmuxinator** — wrong language (Python/Ruby) at
  runtime, and the wrong model (restart-from-config rather than
  manipulate-live-panes). Design references only.
- **sqlite or any external database** — the spec forbids it; the pane
  attribute is the store and auto-GCs on `kill-pane`.
- **A snippet/bookmark manager (`pet`, `buku`)** — the wrong abstraction
  for structured input prompts; a prompt library (gum, Inquirer.sh) is
  correct.
- **smenu** — overkill for a one-shot chooser; fzf's stdin/stdout contract
  is all the chooser needs.
- **A dedicated config parser (crudini, TOML/YAML CLI)** — overkill for a
  flat `key:value` format; `bash read` is the whole parser.

---

## Command-surface rationale

The configuration surface is intentionally small — fewer flags to parse,
fewer options to document, fewer code paths to test. The surface has three
parts: the **CLI** (what the user types or binds), the **tmux options**
(static config read by the runtime), and the **definition-file keys**
(per-utility and per-layout settings). Dynamic per-pane state is **not**
part of the configuration surface — it lives in the pane title, not in any
option or file.

A count of the reducible surface:

- **CLI flags:** 0 — every behavior is a command, a positional, or context.
  The chooser is implicit.
- **tmux options:** 4 — all static config, read by the runtime
  (`@tum-chooser`, `@tum-host-glyph`, `@tum-borrowed-glyph`,
  `@tum-hidden-session`).
- **definition keys:** 6 utility special keys + 2 layout special keys —
  `command`, `args`, `cwd`, `slot`, `input`, `use-process-env`;
  `layout_id`, `focus`. Environment variables are not keys — any
  non-special line is one. Members are top-level lines, not a key.
- **`tum borrow` modes:** 4 — default (reuse-or-create), `tum new`
  (always-create, owned), no-name `borrow` (chooser over all), no-name `new`
  (chooser over all, always-create on pick). `tum new` is a sibling command
  that skips the reuse-hidden branch, so the resolution matrix lives only
  in `tum borrow`.
- **flip-flop variants:** 2 — by slot (`<prefix> H <slot>`), and
  context-aware (`<prefix> H`, realized as `H Enter` in the keymap).

A few choices that shaped the surface, stated plainly:

- **State is not part of the configuration surface.** Dynamic per-pane state
  lives in the pane title as a `tum:`-prefixed string, not in any option or
  file. It is read and written through one `tum-state` function group.
  Static config (the four `@tum-*` options) is separate and never changes
  at runtime.
- **Environment variables are not keys.** Any non-special `key:value` line
  in a utility file is an environment variable; there is no `env` prefix
  and no comma-separated array. `use-process-env` lets the live environment
  override the file's defaults.
- **The chooser is implicit.** No command carries an `--interactive` flag.
  When a command must choose among several candidates, it calls
  `tum-chooser` internally; if none is installed, the command errors or
  prints a numbered list.
- **`tum new` vs `tum borrow`.** They differ in one thing: `new` always
  creates an owned instance (home = current pane); `borrow` reuses a hidden
  instance first and only creates a pool instance as a last resort.
- **The keymap is a file, not a generator.** The bindings ship as
  `tum-bindings.conf`, sourced from `tmux.conf`. Remapping is a direct edit
  to that file — no per-key options, no generator to run.
- **`input` arguments are prompted only at create time.** `tum borrow` that
  reuses an existing instance never prompts; `tum new` (and `tum borrow`'s
  create branch) collect every `input` value before any tmux mutation.

### What was dropped (and why)

Earlier drafts carried more surface. The drops, with one-line reasons:

| Dropped | Why |
| --- | --- |
| `--new`, `--existing`, `--tag`, `--interactive`, `--pane`, `--prompt` flags | Converted to commands (`new`, `prompt`), to context, or to implicit chooser behavior. The CLI is now flag-free. |
| `on_exit` definition key | Closing a pane ends tmux-borrow's interest in it; no exit policy. |
| `tags` definition key + `@tum-tags` + `--tag` | The chooser's fuzzy filter covers borrow-by-category. |
| `@tum-key-*` (8 options), `@tum-entry-mode`, `@tum-no-prefix-entry`, `@tum-leader` | Remapping is done by editing `tum-bindings.conf` directly; no per-key options or generator. |
| `@tum-host-slots` window-scope cache | A window-scope cache that contradicted state-on-panes; host slots are derived by scanning panes. |
| `members:` wrapper in layouts | Replaced by a flat DSL — each member is a top-level `key:value` line parsed by the same loop as utility files. |
| `bindings` tmux generator command | Replaced by a shipped static `tum-bindings.conf`. |

---

## Design validation — key scenarios

These scenarios exercise the non-obvious decisions in the spec. Each is a
test: if any requirement it lists is not met, the scenario fails. (The full
build plan maps every behavior to a `make test-NN` step in
`implementation-roadmap.md`.)

**Borrow a layout, close one member, recreate it.** A layout `dev`
(editor, term, logs) is borrowed; `logs` is closed; `tum new logs`
recreates it. After the close, `editor` and `term` continue with their
`lay` field unchanged; the fresh `logs` carries the same `lay` id, so it
rejoins the group for group flip-flop. Validates: layouts, context-aware
close, borrowing modes, and that a layout is just an id on panes (nothing
to repair).

**Two borrowed utilities on one host, hide one from the host pane.**
`htop` (slot `1`) and `lazygit` (slot `2`) are both borrowed; from the host
pane, `<prefix> H 1` hides only `htop` and leaves `lazygit` shown; pressing
it again shows `htop` at its last geometry. Validates: slot-keyed flip-flop
(unique within a host window) and that hide clears the host binding but
keeps geometry.

**Push a utility from one session, pop it in another.** `htop` is borrowed
in session `a`; `tum push` detaches it (no host, a push-seq, geometry
recorded); in session `b`, `tum pop` attaches it at the recorded geometry.
Validates: push/pop is independent of the pool/owned distinction
(`home` untouched), and a pushed pane is not reachable by `tum flip`.

**Borrow existing vs borrow new.** Two hidden `ranger` pool instances
exist; `tum borrow ranger` opens the chooser and reuses one; `tum new
ranger` creates a third, owned instance; `tum borrow ranger` again opens
the chooser over the remaining hidden instances (there is no
"only-existing" mode). Validates: the resolution order and the
owned-vs-pool distinction.

**Host pane dies — orphan detection and recovery.** `htop` is borrowed
beside host `%5`; the user kills `%5` with tmux's own `kill-pane`. `tum ls`
shows `htop` as an orphan (`host gone`); `tum borrow htop` re-binds it to
the current host. Validates: lazy orphan detection (no hook fired on
death), the binding left intact and marked `!` until the user acts, and
that re-borrowing clears the dead binding.

**Slot key conflict — auto-assignment.** `htop` defines `slot: 1` and
`lazygit` also defines `slot: 1`; both are borrowed to the same host.
`htop` gets slot `1`; `lazygit`'s declared slot conflicts, so it is
auto-assigned the next free slot (e.g. `2`). Validates: slot uniqueness
within a host window and auto-assignment on conflict.

---

## Companion documents

- `docs/tmux-borrow-requirements.md` — the spec (the *what*).
- `docs/implementation-roadmap.md` — the build plan (phases, steps, Make targets).
- `man/` — the manpage sources, rendered by `make man`.
