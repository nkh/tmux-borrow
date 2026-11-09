# tmux-borrow — component analysis

## Which existing projects can be reused to build each component

> **Scope.** tmux-borrow is a small Bash orchestration layer over tmux. It keeps all state in tmux pane-scope user options (no external database), borrows utility panes beside a host pane, toggles them with slot keys, closes them with `kill-pane`, and composes working sets with push/pop and import. The runtime is Bash-only (Perl acceptable for short helpers; no Python in runtime code). This document maps each component to existing open-source projects that could be reused to implement it, so the build does not reinvent what already exists. Every project cited below was verified against its real repository; URLs and licenses are taken from the projects themselves.

The companion specs define the components this analysis covers:

- `tmux-borrow-requirements.md` — the core model, the chooser contract, the definition format, the `tum-tmux`/`tum-state` modules, orphan handling, and the implementation constraints.
- `tmux-borrow-keymap.md` — the key-binding layer that drives those commands.

---

## Summary recommendations

| #   | Component                     | Recommendation                                                                                                     |
| --- | ---                           | ---                                                                                                                |
| 1   | Interactive picker (chooser)  | **fzf** as the reference `tum-chooser`; **skim** as a Rust-binary alternative.                                     |
| 2   | Config file parsing           | **Plain `bash read`** in a `while IFS=: read -r key value` loop. No library.                                       |
| 3   | Structured input prompts      | **gum** (`gum input`/`gum choose`) for prompts; **Inquirer.sh** for zero-dependency. Not a snippet manager.        |
| 4   | Popup / overlay rendering     | **tmux `display-popup`** (tmux ≥ 3.2). No alternative needed.                                                      |
| 5   | tmux interaction (`tum-tmux`) | **Write it in Bash.** `libtmux` is the design reference but is Python (disqualified at runtime).                   |
| 6   | Process info capture (import) | Read **`/proc/$pid/{cmdline,cwd,environ}`** directly (split on NUL with `tr`). `ps`/`pstree` only locate the pid.  |
| 7   | State storage (`tum-state`)   | **tmux pane-scope user options** (`@tum-*` via `-p`, tmux ≥ 3.0). No external DB.                                  |
| 8   | Bash completion               | Write against the **bash-completion** API (`_init_completion`), with a hand-rolled `complete -F` fallback.         |
| 9   | Status bar / prompt glyphs    | tmux **`#(tum status …)`** interpolation + a sourced **Bash snippet**; optional **starship**/**p10k** segments.    |
| 10  | Testing                       | **bats-core** against `tmux -L tum-test -f /dev/null`; **shellcheck** and **shfmt** as CI gates.                   |
| 11  | Packaging / distribution      | **`make install`** baseline + a **Homebrew formula** + an **Arch AUR** `PKGBUILD`; document git-clone-and-symlink. |

The detail sections below justify each pick and list the alternatives considered.

---

## 1. Interactive picker (the chooser)

The requirements define a chooser contract — `tum-chooser <prompt> <items_file> <output_file>` — and an fzf-based reference implementation. The chooser is an external script, not a core dependency; the core works without one installed.

- **fzf** — A general-purpose command-line fuzzy finder; the de-facto reference. — https://github.com/junegunn/fzf — MIT (Go). Reads newline-separated candidates on stdin, prints the selection on stdout; trivially wrapped as `tum-chooser` (read `items_file`, run `fzf`, write the pick to `output_file`). Popup embedding via `fzf --tmux` or the `fzf-tmux` wrapper. This is the right default.
- **skim (`sk`)** — A Rust reimplementation of fzf with a near-identical CLI. — https://github.com/skim-rs/skim — MIT (Rust). A drop-in alternative if a single static Rust binary is preferable to a Go binary; ecosystem and tmux integration are thinner than fzf's.
- **gum `choose`** — Charm's shell-script toolkit, `choose` subcommand. — https://github.com/charmbracelet/gum — MIT (Go). Usable but less scriptable than fzf (no exit-key handling, less preview control); better suited as a prompter (see §3) than as the chooser.
- **peco** — Simplistic interactive filtering tool, the predecessor of fzf. — https://github.com/peco/peco — MIT (Go). Functionally equivalent but lower maintenance and fewer features; historical prior art only.
- **smenu** — A heavyweight, scriptable terminal selection tool (search, multi-select, checkboxes). — https://github.com/p-gen/smenu — MPL-2.0 (C). Powerful but overkill for a one-shot chooser; its feature surface conflicts with tmux-borrow's minimal-dependency ethos.

**Recommendation: fzf.** It matches the contract exactly, ships with tmux popup support, and is what the requirements name. A user who prefers Rust can point `@tum-chooser` at a skim wrapper; nothing else in the project changes.

---

## 2. Config file parsing

Definitions are a flat `key:value` text format, one file per definition, no sections, no hierarchy, no quoting. This is the simplest possible configuration shape.

- **bash `read`** — The built-in `while IFS=: read -r key value; do ...; done` parses `key:value` lines directly. — POSIX/Bash built-in. This is the correct default. There is nothing for a parser library to add: no quoting, no escapes, no nested structures means one `read` loop per file is the whole parser. Recommended.
- **awk one-liners** — `awk -F: '{print $1, $2}'` for a single field transform. — POSIX awk. Useful only if a field needs filtering or reformatting at parse time; for plain load-into-associative-array, `read` is simpler and faster.
- **dedicated key-value parsers** — `crudini`, TOML/YAML CLI parsers, vifm-style formats. Explicitly overkill. They exist to handle sections, nesting, quoting, and comments — none of which apply here. Adding one would introduce a runtime dependency for zero benefit. Do not use.

**Recommendation: plain `bash read`.** The `tum-state` module's definition loader is a `read` loop; nothing else is needed.

---

## 3. Structured input prompts

When a utility launches without its required args, or named-import captures name/command/cwd/env, the tool must prompt for several structured values inside a terminal. A prompt library fits; a snippet/bookmark manager does not.

- **gum** — Charm's shell-script toolkit: `gum input`, `gum choose`, `gum confirm`, `gum file`. — https://github.com/charmbracelet/gum — MIT (Go). Best pick for structured prompts. Each field is one `gum input --prompt "Command: " --placeholder …` call, output captured with `$(...)`. Single static binary, no shell deps. Run inside `display-popup` for a TTY.
- **Inquirer.sh** — A dependency-free collection of Bash interactive prompts (list, text input) inspired by Inquirer.js. — https://github.com/kahkhang/Inquirer.sh — MIT (pure Bash). Ideal for zero external binaries: source a few Bash functions and the prompts render themselves. Lower polish than gum but no runtime dependency.
- **whiptail (newt)** — `whiptail --inputbox`/`--menu`/`--checklist`; ships with util-linux/newt on essentially every distro. — https://fedorahost.org/wiki/Whiptail (libnewt) — LGPL-2.0 (C). Maximally available (no install on most systems) and good for full-screen forms, but the API is clunky for one-line field prompts and output goes through fd 3.
- **dialog** — Thomas Dickey's curses dialog box program, superset of whiptail. — https://invisible-island.net/dialog/ — LGPL-2.0 (C). Same model as whiptail with more widgets; not installed by default on Debian-family systems. Use only if its mixed forms are wanted.
- **pet** — Simple command-line snippet manager (save, tag, search, execute command snippets). — https://github.com/knqyf263/pet — Apache-2.0 (Go). **Not a good fit.** `pet` stores and recalls whole canned command lines from its own TOML store; it does not expose a general "prompt me for N named fields" API. It would force tmux-borrow to model its definitions as `pet` snippets, leaking `pet`'s data model. Listed to answer the question directly.
- **buku** — Browser-independent bookmark manager (URLs, tags, titles). — https://github.com/jarun/buku — GPL-3.0 (Python). Does not fit at all: it is a Python bookmark database, doubly wrong (the no-Python rule, and its domain is URLs not command definitions).

**Recommendation: gum** for prompts, with Inquirer.sh as the zero-dependency fallback. A snippet/bookmark manager (`pet`, `buku`) is the wrong abstraction — it imposes its own data model rather than letting tmux-borrow prompt for the fields it needs.

---

## 4. Popup / overlay rendering

The chooser and prompts render inside a tmux overlay so they float above the host pane.

- **tmux `display-popup`** — Built-in tmux command for per-client transient popups connected to an external command. — https://github.com/tmux/tmux (man tmux, `display-popup`) — ISC/BSD (tmux license). Added in tmux 3.2. The canonical answer. API: `tmux display-popup -E -w 80% -h 80% 'tum-chooser …'` runs a command in the popup and closes it on exit. The popup's stdin/stdout are the popup's own pane, not the caller's — so tmux-borrow bridges data through temp files or pane-scope options, exactly the storage model the requirements specify. The `-E` flag closes the popup on command exit; `-C`/`-B` give close/queue hooks.
- **tmux-floax** — "The missing floating pane for Tmux": a managed floating pane with persistent state and shortcuts. — https://github.com/omerxx/tmux-floax — GPL-3.0 (shell). Solves a different problem (a permanent scratch floating pane you toggle), not a per-invocation chooser overlay. Useful only as prior art for popup-bridge patterns. Note GPL-3.0 is copyleft if code were vendored.
- **tmux-fzf** — Plugin that wraps fzf in a `display-popup` to manage tmux panes/windows/sessions. — https://github.com/sainnhe/tmux-fzf — MIT (shell). Directly demonstrates the popup+fzf pattern tmux-borrow wants; worth reading for the bridge technique, but it owns its own popup lifecycle so it would not be embedded.

**Recommendation: `display-popup` directly.** No alternative adds enough value to justify the dependency. tmux-borrow's chooser-contract file-bridge (§1) is the workaround for the popup's disconnected stdin/stdout.

---

## 5. tmux interaction (`tum-tmux` module)

The requirements mandate one `tum-tmux` module wrapping every tmux call (`new-session`, `join-pane`, `move-pane`, `move-window`, pane-id verification, version quirks). The rest of the code never calls `tmux` directly.

- **libtmux** — A typed Python API over tmux (Server/Session/Window/Pane objects). — https://github.com/tmux-python/libtmux — MIT (Python). **Does not fit** — it is Python, which the no-Python-in-runtime rule forbids. Useful only as a design reference for the object model and option-handling patterns the `tum-tmux` module should expose.
- **tmuxp** — Session manager that builds tmux sessions from declarative YAML workspace files, powered by libtmux. — https://github.com/tmux-python/tmuxp — MIT (Python). Different model: tmuxp restarts a fixed set of processes from a config each time a workspace loads. tmux-borrow instead borrows live panes and stores ephemeral state in tmux options, never restarting anything. Also Python, so excluded at runtime. The contrast is informative: tmuxp is "declare desired layout, rebuild it"; tmux-borrow is "manipulate what is already running".
- **tmuxinator** — Ruby tmux session manager, the original YAML-to-tmux tool. — https://github.com/tmuxinator/tmuxinator — MIT (Ruby). Same restart-from-config model as tmuxp; same contrast applies. Also Ruby, so excluded at runtime.
- **No widely-used pure-Bash tmux wrapper exists.** Most Bash tmux tooling (tmux-resurrect, tmux-fzf, tmux-floax) calls `tmux …` directly through small helper functions. This validates tmux-borrow's own thin `tum-tmux` wrapper as the right approach: write it in Bash, model the API on libtmux's option/pane helpers, but keep it dependency-free.

**Recommendation: write `tum-tmux` in Bash.** libtmux is the design reference; no existing Bash wrapper is worth vendoring. The module's job is narrow (quoting, pane-id verification, version quirks in one place), and a hand-rolled ~100-line wrapper is smaller and clearer than any dependency.

---

## 6. Process info capture (for named import)

Named import reconstructs a pane's command, args, cwd, and env at max fidelity from `/proc/$pid/`.

- **`/proc` filesystem** — The kernel exposes `/proc/$pid/cmdline` (NUL-separated argv), `/proc/$pid/cwd` (symlink to the cwd), and `/proc/$pid/environ` (NUL-separated `KEY=VALUE` pairs). — Linux kernel. The highest-fidelity source. Read with `tr '\0' '\n' < /proc/$pid/cmdline` (args), `readlink /proc/$pid/cwd` (cwd), and `tr '\0' '\n' < /proc/$pid/environ` (env). Nothing beats it for a running process.
- **procps-ng (`ps`)** — The `ps` from procps-ng, plus the suite (`top`, `free`, `pgrep`, `pmap`). — https://gitlab.com/procps-ng/procps — GPL-2.0-or-later (C). `ps -o args= -p $pid` gives the command line, but reformatted and truncating long args — strictly lower fidelity than reading `/proc/$pid/cmdline` directly. Use only for the pane's foreground-pid lookup, not for the invocation capture.
- **psmisc (`pstree`, `killall`, `fuser`)** — Tree-of-processes viewer and signal helpers. — https://gitlab.com/psmisc/psmisc — GPL-2.0 (C). `pstree -p` helps identify which child of the pane's shell is the actual foreground process (relevant for capturing a real program rather than the shell), but it does not print re-runnable invocations and does not parse the `/proc` NUL formats. Useful adjunct, not a substitute.

No standard CLI tool reassembles a re-runnable command line from `/proc` NUL-separated data — that is the small Perl/Bash helper tmux-borrow writes itself. Reading the three `/proc` files is the implementation.

**Recommendation: read `/proc/$pid/{cmdline,cwd,environ}` directly.** Use `ps`/`pstree` only to locate the foreground pid when the pane's pane pid is a shell.

---

## 7. State storage (`tum-state` module)

All state lives in tmux pane-scope user options (`@tum-*` via `tmux set-option -p` / `show-options -p`). The requirements mandate this and forbid any external database.

- **tmux pane options (`-p`)** — tmux's per-pane option scope. — https://github.com/tmux/tmux (man tmux, OPTIONS) — ISC/BSD. Confirmed viable. Pane options were introduced in **tmux 3.0** (upstream CHANGES: "Add pane options, set with set-option -p and displayed with show-options -p"). Pane options are a pane attribute and travel with the pane across `move-pane`/`join-pane`/`link-window`, including across sessions, because they are bound to the pane object, not the window or session. User options (the `@`-prefixed namespace) are accepted at every scope, so `@tum-*` set with `-p` is valid. Require tmux ≥ 3.0 in the README.
- **tmux-resurrect** — Persists the full tmux environment across system restarts. — https://github.com/tmux-plugins/tmux-resurrect — MIT (shell). Prior art for "tmux state is worth persisting", but it persists to plain-text files under `~/.local/share/tmux/resurrect/`, **not** to tmux options. The contrast is informative: resurrect needs cross-restart durability so it uses files; tmux-borrow needs live, in-band, pane-attached state so it uses pane options. Different need, different (correct) choice.
- **No external DB needed.** sqlite, JSON files, or a state daemon would each add a runtime dependency, a second source of truth that can drift from tmux's reality, and a cleanup problem when panes die. Because every piece of tmux-borrow state is keyed to a specific pane (slot assignments, borrowed-set membership, import metadata), storing it as a pane-scope option keeps it automatically garbage-collected by `kill-pane`. No external DB is needed; pane options are the right store.

**Recommendation: pane-scope `@tum-*` options, wrapped by one `tum-state` module.** The encoding rules live in that one module so they are implemented once. Require tmux ≥ 3.0.

---

## 8. Bash completion

tmux-borrow ships completion for subcommands, utility names, and layout names.

- **bash-completion** — The de-facto collection of completion recipes and helpers for Bash. — https://github.com/scop/bash-completion — GPL-2.0-or-later (Bash). The standard framework. API: ship a `_tum()` function that calls `_init_completion -n :` (or hand-rolls on `COMPREPLY`/`cur`/`prev`/`words`), then `complete -F _tum tum`. Install to `/usr/share/bash-completion/completions/tum` (or `$BASH_COMPLETION_USER_DIR/completions/`). For second-level completion (utility/layout names) read them from the definition directory.
- **Hand-rolled `complete -F`** — A standalone function with no bash-completion dependency. — Bash built-in. Works on minimal systems where bash-completion is not installed, but reimplements the `cur`-splitting and colon-word handling that bash-completion already gives. Acceptable fallback, not the primary path.

**Recommendation: write against the bash-completion API (`_init_completion`), with a graceful hand-rolled fallback if the helper is absent.**

---

## 9. Status bar / prompt glyphs

`÷`/`§`/`!` glyphs surface in the tmux status bar via `tum status`, and in the bash prompt via a sourced snippet.

- **tmux `#(...)` status interpolation** — tmux evaluates `#(shell-command)` inside `status-format`/`status-left`/`status-right` and substitutes its stdout. — https://github.com/tmux/tmux (man tmux, FORMATS) — ISC/BSD. The canonical mechanism. `set -g status-right '#(tum status --pane=#{pane_id})'` re-runs `tum status` on each status refresh and interpolates the glyphs. Confirmed correct.
- **starship** — Minimal, fast, cross-shell prompt with a custom-command module. — https://github.com/starship/starship (homepage https://starship.rs) — ISC (Rust). The right integration target for users who already run starship. A `[custom.tum]` module runs `tum status --prompt` and renders the glyphs; users opt in by adding the module to their starship config. tmux-borrow ships a documented snippet rather than auto-modifying starship config.
- **powerlevel10k** — Fast, flexible Zsh theme with a custom-segment API. — https://github.com/romkatv/powerlevel10k — MIT (Zsh). Zsh-only (narrower audience than starship), but very popular. Integration is a `p10k segment` function calling `tum status --prompt`; ship as a documented snippet, not a hard dependency.

**Recommendation: ship a small sourced Bash snippet (`tum prompt` emitting the glyphs into `PS1`) as the default, plus optional one-block snippets for starship and powerlevel10k custom segments.** Do not auto-patch users' prompt configs.

---

## 10. Testing

Integration tests run against a private tmux server socket (`tmux -L tum-test -f /dev/null`), never the user's default server.

- **bats-core** — Bash Automated Testing System, TAP-compliant. — https://github.com/bats-core/bats-core — MIT (Bash). The standard choice. A test drives the private socket directly: `tmux -L tum-test new-session -d; run tum -L tum-test borrow foo; [ "$status" -eq 0 ]`. The `run`/`$status`/`$output` helpers and per-file `setup`/`teardown` are exactly what is needed. The `bats-support`/`bats-assert` helper libraries (same org, MIT) give `assert_success`/`assert_output`.
- **shellcheck** — Static analysis/linting for shell scripts. — https://github.com/koalaman/shellcheck — GPL-3.0 (Haskell). Mandatory CI gate. Run `shellcheck -x tum tum-chooser tum-tmux tum-state` (the `-x` follows `source`). Catches the quoting/word-splitting bugs that bite tmux wrappers.
- **shfmt** — Shell parser/formatter from mvdan/sh. — https://github.com/mvdan/sh — BSD-3-Clause (Go). The standard formatter. `shfmt -i 2 -ci -bn -w` enforces consistent style across the Bash files; orthogonal to bats and shellcheck.

bats drives the private tmux server simply by passing `-L tum-test` (a named, unshared socket) and `-f /dev/null` (no user config) to every `tmux` invocation in the tests, with a `teardown` that `tmux -L tum-test kill-server`'s for a clean slate.

**Recommendation: bats-core for integration tests, with shellcheck and shfmt as CI gates.**

---

## 11. Packaging / distribution

A Bash project with a `tum` entrypoint plus a `tum-chooser` script, to be installed on PATH. The common options:

- **`make install`** — The classic pattern: a `Makefile` with `install: install -Dm755 tum $(DESTDIR)$(PREFIX)/bin/tum` and the same for `tum-chooser`, completion, and any sourced prompt snippets. — POSIX make. The lowest-common-denominator option; works on every Unix without a package manager. Recommended baseline.
- **Homebrew formula** — A Ruby formula in a tap that `brew install tum` builds from source or bottles. — https://docs.brew.sh/Formula-Cookbook — The standard macOS/Linuxbrew path; a formula is ~20 lines for a Bash-script install. Ship in your own tap (`brew tap user/tum`).
- **Arch AUR package** — A `PKGBUILD` (Bash) in the Arch User Repository that `makepkg`s the scripts into `/usr/bin`. — https://wiki.archlinux.org/title/Arch_User_Repository — The Arch path; `tum` and `tum-chooser` go in `package()` via `install -Dm755`.
- **git-clone-and-symlink** — `git clone … && ln -s "$PWD/tum" ~/.local/bin/tum`, optionally automated with GNU `stow` or `make link`. — shell. The zero-package-manager path; simplest for power users and for development checkouts.

No single option is required. The usual approach is a `make install` baseline plus a Homebrew formula and an AUR `PKGBUILD` for the two big package ecosystems, with the symlink method documented for everyone else.

**Recommendation: ship a `make install` Makefile as the baseline, plus a Homebrew formula and an Arch AUR `PKGBUILD`, and document the git-clone-and-symlink method for development.**

---

## What is deliberately not reused

A few tempting dependencies are explicitly rejected, with the reason:

- **libtmux / tmuxp / tmuxinator** — wrong language (Python/Ruby) at runtime, and the wrong model (restart-from-config rather than manipulate-live-panes). Design references only.
- **sqlite or any external database** — the requirements forbid it; pane-scope options are the store and auto-GC on `kill-pane`.
- **A snippet/bookmark manager (`pet`, `buku`)** — the wrong abstraction for structured input prompts; a prompt library (gum, Inquirer.sh) is correct.
- **smenu** — overkill for a one-shot chooser; fzf's stdin/stdout contract is all the chooser needs.
- **A dedicated config parser (crudini, TOML/YAML CLI)** — overkill for a flat `key:value` format; `bash read` is the whole parser.

The throughline: tmux-borrow is small, Bash-only, and stores state in tmux itself. The reusable projects that fit are the ones with no runtime language dependency (fzf, gum, bats, shellcheck, shfmt) or that are already part of tmux (`display-popup`, `#(...)` interpolation, pane options). Everything else is a few dozen lines of Bash.
