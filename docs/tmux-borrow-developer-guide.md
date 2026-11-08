# tmux-borrow

## Borrow your running tools into the window where you're working — don't relaunch them.

> **Developer guide.** This document is written for the people most likely to feel the pain tmux-borrow solves: developers, terminal power users, and anyone who keeps a dozen long-lived tools alive in tmux and is tired of nursing them. It explains the model, walks through real workflows, and shows how to drive the tool from scripts and CI.

---

### The 30-second pitch

You keep `htop`, `lazygit`, a log tail, a database console, and a REPL running in tmux because starting them cold every time is slow and loses state. The problem is *geography*: the tool lives in one session, your work lives in another, and tmux has no first-class way to say "bring that already-running pane over here next to my editor, and put it back when I'm done." So you either switch sessions constantly, or you give up and `split-window` a fresh copy — which means a new process, a new connection, lost scrollback, a database session you have to re-establish.

**tmux-borrow** (alias `tum`) is the missing primitive. It treats your long-running tools as managed *instances* that live in *home* locations, and gives you one verb — **borrow** — that moves the *running* pane into your current window without restarting the process. When you're done, **return** puts it back. The process keeps its PID, its connection, its scrollback, its state. You stop restarting tools. You start moving them.

It is built as a set of small, composable Unix-style commands (`tum run`, `tum borrow`, `tum return`, `tum layout`, `tum doctor`) over a SQLite metadata store, with TOML for human-edited definitions. Every command works non-interactively with stable IDs and JSON output, so the same tool you drive from a popup you can drive from a script or a pipeline step.

> **Status note.** tmux-borrow is a fully specified tool moving through a phased implementation plan (Phases 0–10, from "freeze decisions" through "lifecycle and release"). The CLI surface is finalized in the command index but a few flag spellings are still being frozen, and earlier drafts used the verbs `launch`/`kill`/`ui` where the canonical index now uses `run`/`stop`/`popup`. This guide describes the product as specified — the model, the safety guarantees, and the flags shown are taken straight from the design docs — so you can see exactly what you're getting and start planning how it fits your workflow and your scripts. Where a name is still provisional, it's called out.

---

## The problem, concretely

Picture a normal afternoon. You have a `tools` session with `htop`, a `tail -F` on the app log, and `lazygit`. You have a `project` session with your editor and a shell. Three times in the next hour you want to glance at the log *next to* the code that's misbehaving. Your options today:

1. **Switch to the `tools` session**, read, switch back. You lose your place, your editor scroll position, your mental stack.
2. **Open a new split and start another `tail`**. Now you have two tails of the same log, two processes, and you'll forget to kill one.
3. **`tmux join-pane`** the log pane manually. This works — once. There's no record of where it came from, nothing puts it back, and if you fat-finger the target you've just moved your editor into the tools session. There is no undo.

The deeper issue is that tmux treats panes as anonymous geometry. It doesn't know that *this* pane is "the app log," that it "belongs" in the tools session, or that it's "borrowed" and should go home. So every move is a one-way trip you have to reverse by hand, and every reversal is an opportunity to destroy state you cared about.

Now multiply by the things developers actually keep running: file managers (`lf`, `ranger`), REPLs (`ipython`, `irb`, `node`), database consoles (`psql`, `redis-cli`), debuggers, profilers, build watchers, network monitors (`nload`, `iftop`), serial consoles, SSH pools. Each one has setup cost — a connection, a working directory, a search history, a breakpoint set. Restarting any of them is a small tax; restarting all of them, repeatedly, is the kind of friction that makes people reach for a heavier window manager instead of fixing the actual gap.

tmux-borrow fixes the gap by giving panes **identity** and **ownership**, so a move is reversible, auditable, and safe.

---

## The one idea

A **definition** is a recipe: "the log viewer is `tail -F /var/log/syslog`, lives in the tools session, exits to a shell." An **instance** is one running copy of that recipe: a real process in a real tmux pane, with a stable ID, tracked in SQLite. Instances live in **home** sessions/windows when nobody's looking at them. When you need one, you **borrow** it into your **working window** — the pane is moved, not relaunched, so the process keeps running. When you're done, you **return** it home. The whole time, the manager knows exactly what it owns, where every owned pane is, and what's borrowed versus at home.

That's it. Everything else — layouts, presets, ad-hoc launches, host-pane anchoring, recovery — is machinery around that one idea. The power comes from how faithfully the model preserves the invariants tmux itself doesn't give you: a pane is in exactly one window; a borrowed pane has a recorded home to go back to; ordinary panes you didn't ask the manager to touch are never touched.

---

## Your first borrow

Assume `tum` is on your `PATH` and you've run the setup wizard once (`tum setup`, which writes a minimal config and a private metadata directory). The happy path, end to end:

```sh
# 1. Register a log viewer (interactive wizard appends a TOML definition)
tum define add --wizard

# 2. Start it — it launches in its own managed home window and is tracked
tum run logs

# 3. From a totally different window — your editor window — borrow it in
tum borrow --fzf          # pick "logs", choose pane or window mode

# 4. The running tail pane is now sitting beside your editor. Do your work.

# 5. Send it back home when you're done
tum return --fzf
```

Between steps 3 and 5, the `tail` process never stopped. Its PID didn't change. Its scrollback is intact. You didn't open a second tail; you moved the one that was already running. And the pane you moved it *next to* — your editor — was never at risk, because the manager only moves panes it can prove it owns.

That's the whole experience. The rest of this guide is about everything you can do once that primitive exists.

---

## The mental model, in one table

| Term                    | Meaning                                                                             | Why it matters                                                   |
| ---                     | ---                                                                                 | ---                                                              |
| **Definition**          | Saved recipe for a utility: command, args, scope, home, exit policy. TOML.          | You write it once; you launch from it many times.                |
| **Instance**            | One running process = one managed tmux pane, with a stable UUID. Tracked in SQLite. | This is the thing you borrow. Stable ID = scriptable.            |
| **Home session/window** | Where an instance lives when not borrowed.                                          | The "parking spot" the pane always returns to.                   |
| **Working window**      | The tmux window where you're actually doing work.                                   | Where borrowed panes get dropped beside your editor.             |
| **Borrow**              | Move an existing running pane (or window) into a working location.                  | The core verb. No restart, no lost state.                        |
| **Return**              | Move a borrowed pane/window back to its recorded home.                              | The reverse of borrow. Restores any temporary appearance.        |
| **Host pane**           | The pane beside which a utility is borrowed (insertion anchor). User-owned.         | Anchors placement; manager never alters its process.             |
| **Shared instance**     | One instance, borrowed by different windows — one at a time.                        | For global tools: one `htop`, borrowed wherever.                 |
| **Per-window instance** | An instance tied to one stable working-window record.                               | For project-scoped tools: a file manager per project.            |
| **Layout**              | A named recipe of *managed* utility panes and their arrangement.                    | Save/restore a whole borrowed toolset; ordinary panes untouched. |
| **Preset**              | A named set of argument values for one utility.                                     | "project-a" preset for `ranger` → `/work/project-a`.             |
| **Ad-hoc utility**      | Launched without a saved definition, via `tum run -- ...`.                          | First-class: tracked and borrowable like any registered tool.    |

The two distinctions worth internalizing: **definition vs. instance** (recipe vs. running copy — you can have many instances of one definition), and **home vs. working window** (where a pane parks vs. where it does duty). Borrowing is the act of moving an instance from the former to the latter and back.

---

## Real workflows

These are the workflows the tool was designed around, each with the commands you'd actually type. They map to the project's own use-case catalog, distilled to the ones a developer hits weekly.

### 1. A per-project file manager that follows the project

You want `lf` rooted at the project you're working in, but you don't want one `lf` per window leaking across context switches. Make the file manager a **per-window** instance: each working window gets its own, scoped to that window, borrowable into a split beside the editor.

```sh
# Register it once, scoped per-window, defaulting to the current window's cwd
tum define add --wizard      # name: project-files, command: lf, scope: window

# In a project window, start its file manager (cwd inherited from the window)
tum run project-files --cwd "$PWD"

# Later, from the editor split, borrow *this window's* file manager beside you
tum borrow project-files --as split
```

Because it's `per_window`, the manager resolves the instance belonging to *this* working window automatically — no ambiguity, no `--instance` needed. Switch to a different project window and you get that window's file manager, not the other one's.

### 2. One shared system monitor, borrowed anywhere

`htop` is `htop`. You want exactly one, living in a background tools session, borrowed into whatever window you're debugging in. That's the **shared** policy.

```sh
tum run htop --scope shared --session tools        # lives in the tools session

# From any project window, any time:
tum borrow htop --as split --yes                   # drops in beside you
# ...glance at CPU/memory...
tum return --instance "$(tum list --format json | jq -r '.instances[] | select(.definition=="htop" and .state=="borrowed").id')" --yes
```

Shared means one borrow at a time — a pane can't be in two windows — so if it's already borrowed elsewhere, the manager tells you rather than silently stealing it.

### 3. Multi-service log triage in one window

A bug spans three services. You want all three logs side by side, right now, without three new `tail` processes fighting your existing ones.

```sh
# Three named log instances, already running in their home session
tum run svc-auth    -- tail -F /var/log/auth.log
tum run svc-api     -- tail -F /var/log/api.log
tum run svc-worker  -- tail -F /var/log/worker.log

# Borrow all three into the current debugging window
tum borrow svc-auth   --as split --yes
tum borrow svc-api    --as split --yes
tum borrow svc-worker --as split --yes

# When the bug is found, return them all at once
tum return --all --yes
```

`return --all` returns only manager-tracked borrowed resources in scope. Your editor and shell — the ordinary panes — are untouched.

### 4. An ad-hoc build log you didn't plan for

You didn't register a definition for "the build log of the thing I just kicked off," and you shouldn't have to. Launch it ad-hoc, give it a name, and it's tracked and borrowable exactly like a registered tool.

```sh
# Ad-hoc: everything after -- is the verbatim argv; --name/--cwd/--on-exit are manager options
tum run --name "build output" --cwd "$PWD" --on-exit wait -- tail -F ./build.log
```

It gets assigned to a session (auto, or one you name with `--session`), gets a stable instance ID, and can be borrowed later from the popup or by ID. "Ad-hoc" does not mean "unmanaged" — there is no separate throwaway launch path.

### 5. A database console that prompts for the target

`psql` is useless without a connection. Register it with a required argument, and the manager collects the value before it moves anything — at the terminal or in a split.

```sh
# Definition declares a required "target" argument (TOML)
# [utility.psql]
# command = "/usr/bin/psql"
# required_args = ["target"]
# [utility.psql.argument.target]
# prompt = "Database / connection profile"
# type = "string"

tum run psql                                   # prompts: "Database / connection profile"
tum borrow psql --as split --arg "prod-ro"     # or pass it directly, no prompt
```

If you omit a required value in non-interactive mode, the command **fails with the names of the missing values** rather than guessing. This is the behavior you want in a script: loud failure, never a launched tool pointed at the wrong database.

### 6. An incident room you can save and replay

A production incident pulls together a debugger, the app log, and the DB console — from three different home sessions. Once you've got them arranged, save *just that borrowed arrangement* as a layout, so the next 3 a.m. page restores the whole room in one command.

```sh
# (after borrowing debugger + two logs into your incident window)
tum layout save incident-room

# ...next incident, in a fresh window...
tum layout restore incident-room --yes
```

A layout contains **only managed utility panes** and their arrangement. It never captures your editor, your shell, or their sizes — so restoring a layout into a window that already has your work in it adds the tool panes around your work instead of resetting the whole window. This is a hard safety requirement, not a best effort.

### 7. A remote shell pool you never reconnect

You SSH to the same five boxes constantly. Keep the connections alive as managed instances in home sessions and borrow the *existing connection* — no re-handshake, no re-auth, no lost history.

```sh
tum run box-edge    -- ssh edge-1.prod
tum run box-db      -- ssh db-1.prod
tum run box-queue   -- ssh queue-1.prod

# From any window, pull one in by name (or fzf over the pool)
tum borrow --fzf
```

The SSH process keeps its connection and its scrollback. When you return it, it goes back to waiting in its home session, still connected.

### 8. Switch task context without losing your window

You're mid-task in a window with logs borrowed in. A teammate drops a different fire on you. You want to swap the *borrowed toolset* for a different saved layout without disturbing your editor and shell.

```sh
# Save what you're currently borrowing as one named layout, swap to another
tum layout save current-task
tum layout restore other-fire --yes      # returns current borrowed set, borrows the new one
```

Your ordinary panes stay exactly where they are; only the borrowed managed panes rotate. This is the "context switch for your tools, not your editor" move, and it's only possible because the manager can distinguish what it owns from what you own.

---

## The command surface

The whole tool is a small set of independent commands. Every command here is the canonical form from the command index; a couple of earlier-draft aliases are noted.

| Command                     | Purpose                                                                                          |
| ---                         | ---                                                                                              |
| `tum list`                  | List definitions and instances (states, home/current locations).                                 |
| `tum define add`            | Add a definition via `--template` (append a commented block) or `--wizard` (readline questions). |
| `tum define edit NAME`      | Open the definition in `$EDITOR`.                                                                |
| `tum define remove NAME`    | Remove after checking for active instances.                                                      |
| `tum run NAME`              | Start a registered utility in its home window.                                                   |
| `tum run -- ...`            | Start an ad-hoc utility; argv after `--` passed verbatim.                                        |
| `tum borrow`                | Borrow the selected instance into the current window (`--as pane`/`window`/`split`).             |
| `tum return`                | Return the selected borrowed instance home.                                                      |
| `tum stop`                  | Stop a selected managed instance (earlier drafts called this `kill`).                            |
| `tum layout list`           | List layouts.                                                                                    |
| `tum layout add`            | Add a layout via `--template` or `--wizard`.                                                     |
| `tum layout edit NAME`      | Open a layout in `$EDITOR`.                                                                      |
| `tum layout save NAME`      | Save the current arrangement of managed panes as a layout.                                       |
| `tum layout restore NAME`   | Restore a layout (earlier drafts: `apply`).                                                      |
| `tum layout clone SRC DEST` | Clone a layout definition without moving source resources.                                       |
| `tum config edit`           | Open the main config in `$EDITOR`.                                                               |
| `tum popup`                 | Open the interactive manager (earlier drafts: `ui`).                                             |
| `tum doctor`                | Check dependencies and reconcile state against live tmux.                                        |

**Selection rules.** If exactly one instance matches a command, it's selected automatically. If several match, you must disambiguate with `--instance ID` or pick interactively (`--fzf`). Multi-select is allowed only for batch-capable commands.

**Common options** (apply across commands): `--instance ID`, `--fzf`, `--all` (only where documented), `--yes` (skip confirmations / non-interactive), `--prompt`, `--format table|json`, and `--` to end manager options and hand the rest to the utility as argv.

---

## Arguments, presets, and secrets

Arguments are stored as an **ordered array (`argv`), never a shell command string.** This is non-negotiable in the design: it preserves spaces and special characters and means the manager never re-parses your arguments through a shell. There is no `sh -c` unless you explicitly choose a shell as the executable. For a tool that launches `psql`, `tail`, and `ranger` with user-supplied paths, this is the difference between "works" and "a quoting bug that deletes the wrong file."

**Precedence** (lowest to highest) determines what value wins when several layers specify one:

| Layer                          | Example                                           |
| ---                            | ---                                               |
| Built-in defaults              | exit policy `wait`, idle `keep_running`           |
| Global config                  | `defaults.scope = shared`                         |
| Utility definition             | `[utility.logs] args = ["-F", "/var/log/syslog"]` |
| Layout item or selected preset | a `project-default` preset for `logs`             |
| Command-line override          | `tum run logs -- /var/log/auth.log`               |

An explicitly supplied **empty** CLI value still counts as an override — you can deliberately clear a default.

**Presets** are named argument sets for one utility, not new definitions:

```toml
[utility.ranger]
command = "/usr/bin/ranger"
required_args = ["root"]
instance_policy = "per_window"

[utility.ranger.argument.root]
prompt = "Directory to browse"
type = "directory"
persist = false

[preset.ranger.project-a]
utility = "ranger"
values = { root = "/work/project-a" }
portable = true
```

Now `tum run ranger` can target the `project-a` preset, and a layout can reference the same preset by name instead of hardcoding a path.

**Secrets are never persisted.** Secret arguments must come from an interactive (non-echoing) prompt or a supported secret provider. They are never written to ordinary config, layout files, the operation journal, or logs — and the argument-save policy explicitly forbids the `values` form for secret arguments. When you save a layout, the per-item policy is one of `omit` (default — store nothing), `preset` (store a named preset reference), or `values` (store explicitly approved non-secret values only). This means a layout is safe to commit to git or hand to a teammate: it carries recipes, not credentials.

---

## Layouts

A layout is a named recipe for assembling **manager-owned utility panes only**. It is not a snapshot of your tmux window, and this distinction is the feature that makes layouts safe.

When you `tum layout save review-tools`, the saved file records the utility references, their instance policy, the split-tree arrangement among managed panes, the destination mode (`current_window` or `separate_window`), optional size proportions, and the argument-persistence policy. It does **not** record your editor, your shell, your ordinary pane sizes, or anything you didn't ask the manager to own.

When you `tum layout restore review-tools`, the manager resolves every definition and instance, checks for conflicts (a utility already borrowed elsewhere is *reported*, not silently stolen), collects any required arguments **before touching tmux**, and then adds the managed panes incrementally. It will not apply a whole-window `select-layout` to a mixed window if that would resize your ordinary panes. If something can't be restored cleanly, it rolls back what it can and reports the precise partial result.

**Clone** creates a new layout record from an existing one without moving any source panes — handy for "give me the project layout but for project-b." `shared` items keep their shared policy, `per_window` items get a fresh instance for the destination window, and you're prompted for destination-specific arguments. Secrets are not copied.

The net effect: layouts let you treat a *set of borrowed tools* as a reusable artifact, the way you already treat a git branch or a docker-compose file.

---

## Scripting and CI

This is where tmux-borrow earns its keep for developers. Because every command accepts `--instance ID` for deterministic selection, `--yes` for non-interactive runs, and `--format json` for machine output, the popup you use at your desk is the exact same interface you call from a shell function, a tmux hook, or a pipeline step. There is no separate "scripting API."

### The three scripting primitives

| Primitive                 | What it gives you                                                                                                  |
| ---                       | ---                                                                                                                |
| `--format json`           | Structured output of definitions, instances, and layouts — pipe to `jq`.                                           |
| `--instance ID`           | Deterministic selection: the same instance every time, no menus.                                                   |
| `--yes`                   | Skip all confirmations; safe for non-interactive (scripted, CI) contexts.                                          |
| `--all`                   | Batch over every matching borrowed resource (e.g. `return --all`).                                                 |
| fail-loud on missing args | In non-interactive mode, a missing required value fails with the names of what's missing — never a guessed launch. |

### Read live state with `jq`

```sh
# What's borrowed right now?
tum list --format json | jq '.instances[] | select(.state == "borrowed")'

# Count, grouped by definition
tum list --format json \
  | jq -r '.instances | group_by(.definition_id)[] | "\(.[0].definition_id): \(length)"'

# Stable ID suffix + state, for a compact status line
tum list --format json \
  | jq -r '.instances[] | "\(.id[0:8])  \(.state)  \(.definition_id)"'
```

Because instance IDs are stable UUIDs (tmux's `$N`/`@N`/`%N` IDs are runtime-only and can change), a script that captures an ID can act on the same instance later without re-resolving it.

### A "focus this project" shell function

Borrow this window's file manager and the shared logs instance beside your editor, non-interactively:

```sh
focus-project() {
  local project="$1"
  local win="${2:-$(tmux display-message -p '#W')}"

  # Per-window file manager for this working window, rooted at the project
  tum run project-files --cwd "$project" --scope window --on-exit wait --yes \
    2>/dev/null || tum borrow project-files --as split --yes

  # Shared logs, borrowed beside whatever's active
  tum borrow logs --as split --yes
}
```

### A layout as a transactional unit of work

Borrow a known toolset, do the review, and guarantee everything goes home — even on error — with a trap:

```sh
#!/usr/bin/env bash
set -euo pipefail

tum layout restore review-tools --yes
trap 'tum return --all --yes' EXIT

# ...run the review; if anything throws, the trap still returns everything...
your-review-command "$@"
```

`return --all` returns only manager-tracked borrowed resources, so the trap can't accidentally close your editor.

### CI: refuse to deploy if someone's mid-debug

A borrowed instance means a human is actively using a tool against live state. Gating a deploy on "nothing is borrowed" is a cheap, real safety check:

```sh
# preflight.sh — run before any production deploy
set -euo pipefail
borrowed=$(tum list --format json | jq '[.instances[] | select(.state == "borrowed")] | length')

if [ "$borrowed" -ne 0 ]; then
  echo "Refusing deploy: $borrowed managed instance(s) currently borrowed." >&2
  tum list --format json \
    | jq -r '.instances[] | select(.state == "borrowed")
             | "  - \(.definition_id) (\(.id[0:8])) borrowed in \(.current_session_id):\(.current_window_id)"' >&2
  exit 1
fi
echo "OK: no borrowed instances. Proceeding."
```

### CI: a reproducible, addressable helper cluster on a fresh runner

You need a mock API, a build watcher, and the app log coordinated for an integration test. Spin them up as managed instances in a detached tmux server so test code can address each by stable ID instead of parsing tmux output:

```sh
set -euo pipefail

# Detached tmux server for the test
tmux new-session -d -s ci -n work
tmux send-keys -t ci:work 'run-the-test-suite' Enter

# Helpers as managed instances — each gets a stable ID the test can query
tum run mock-api       --cwd "$REPO" --yes
tum run --name build-watcher --cwd "$REPO" -- watchexec --restart make build --yes
tum run --name app-log -- tail -F "$REPO/var/log/app.log" --yes

# Test code reads live state without scraping tmux
tum list --format json | jq '.instances[] | {id: .id[0:8], state, pid}'

# Tear down deterministically at the end
tum stop --all --yes
```

### CI: `doctor` as an environment gate

`tum doctor` checks dependencies (tmux, SQLite, the TOML parser, optional fzf) and reconciles metadata against live tmux state. Its exit code is a clean gate:

```sh
tum doctor || { echo "tum environment unhealthy; aborting job." >&2; exit 1; }
```

### One tmux binding, by design

The tool deliberately does not compete with tmux's own navigation, resize, zoom, or copy-mode bindings. The recommended integration is a single key that opens the popup, and the popup delegates to the exact same CLI commands shown above:

```sh
# ~/.tmux.conf — one binding, everything else lives in the popup or the CLI
set -g @tum-popup-key 'u'
bind-key u display-popup -E -w 80% -h 80% 'tum popup'
```

That's the entire keymap. Power users who live in tmux will recognize the restraint: nothing to unlearn, nothing fighting existing muscle memory.

---

## The safety model

This is the part developers care about most, because the thing that makes `join-pane` dangerous is that it doesn't know what it's allowed to move. tmux-borrow's central safety rule is that **the manager may move or stop only panes it can prove it owns** — and proof requires a matching instance record, a manager marker, and a verified live pane identity. A pane name or a matching command line alone is *not* sufficient.

| Resource                 | Owner            | Manager may move?      | Manager may stop?    |
| ---                      | ---              | ---                    | ---                  |
| Managed utility pane     | Manager instance | Yes                    | Yes, explicit action |
| Managed home placeholder | Manager          | Recreate / move        | Yes                  |
| Ordinary user pane       | User             | **No**                 | **No**               |
| User working window      | User             | Add managed panes only | **No**               |
| Managed utility window   | Manager          | Yes                    | Yes, explicit action |

Concretely, this means:

- **Your editor and shell are never moved, killed, or resized** by a utility-only operation. Layouts add managed panes around them; they never reset a mixed window.
- **Stopping requires confirmation** unless you pass `--yes`, and the manager never kills a host pane or an ordinary pane — only the exact managed pane it identified.
- **No `SIGSTOP`/`SIGCONT` by default.** Arbitrary programs lose connections, locks, and state when suspended, so the default idle policy is `keep_running`. Suspension is opt-in per utility, declared as unsafe if needed.
- **Arguments are never re-parsed through a shell.** Argv is an array; there is no interpolation, no `eval`, no quoting trap.
- **Secrets are never persisted** — not in config, layouts, the operation journal, or logs.
- **State files are user-private** (umask 077), and the manager warns on a world-readable state directory.

The exit policy for when a utility's process ends is per-utility, defaulting to `wait`:

| Policy           | Behavior                                                                       |
| ---              | ---                                                                            |
| `wait` (default) | Keep the pane; wait for a key before cleanup so the exit result stays visible. |
| `shell`          | Replace the utility process with an interactive shell.                         |
| `close`          | Close the pane/window.                                                         |
| `leave`          | Leave the pane exactly as-is.                                                  |

---

## Recovery and `doctor`

tmux is not transactional, so the manager keeps an **operation journal**: every multi-step tmux mutation (start, borrow, return, stop, restore, clone) is recorded with its phase (`planned`/`running`/`partial`/`complete`/`failed`) before any pane moves. If a tmux step succeeds but the subsequent metadata commit fails — or your laptop dies mid-borrow — the journal tells the next invocation exactly what was left half-done.

Each instance has a lifecycle state that makes this inspectable:

| State       | Meaning                                    |
| ---         | ---                                        |
| `starting`  | Launch in progress                         |
| `home`      | Running in its managed home pane           |
| `borrowed`  | Running in a working window                |
| `returning` | Return in progress                         |
| `stopped`   | Process ended; pane inactive               |
| `failed`    | Operation failed; needs inspection         |
| `unknown`   | Live tmux state can't be reconciled safely |

`tum doctor` is the reconciliation entry point. It checks dependencies, compares metadata against live tmux sessions/windows/panes, reports missing or orphaned resources, and offers explicit repair actions rather than silently discarding state. A few representative failure modes and the intended behavior:

- **Instance is unknown** (recorded pane can't be proven to exist or belong to the instance): `doctor` reports it; you don't kill a pane based on a similar command line.
- **Host pane moved** by external tmux: the association is marked orphaned; the utility keeps running; the repair action re-links it.
- **Home session was deleted**: the manager recreates it from metadata — it does *not* substitute another same-named session (display names are not identity).
- **Ordinary panes changed during a restore**: that's a defect, by spec. Restore must add managed panes incrementally and never reset a mixed window's whole layout.

The design goal is that you never lose work to a half-finished manager operation, and you never have to guess whether a pane is safe to kill.

---

## Configuration

Human-edited files are **TOML**; runtime metadata is **SQLite** at `$XDG_STATE_HOME/tmux-utility-manager/state.db` (falling back to `~/.local/state/tmux-utility-manager/state.db`). You rarely touch paths directly — `tum config edit` and `tum layout edit NAME` open the right file in `$EDITOR` for you.

A representative definition set, in TOML:

```toml
version = 1

[defaults]
selector = "fzf"
home_session = "auto"
on_exit = "shell"
scope = "shared"
metadata_dir = "${XDG_STATE_HOME:-$HOME/.local/state}/tum"

[utility.logs]
command = "/usr/bin/tail"
default_args = ["-F", "/var/log/syslog"]
cwd = "/"
instance_policy = "shared"
exit_policy = "wait"
borrowed_background = "#263238"

[utility.logs.lifecycle]
idle_policy = "keep_running"

[utility.project-files]
command = "lf"
instance_policy = "per_window"
working_directory = "current-window"

[utility.project-files.split_argument]
prompt = "Directory"
default = "."

[utility.project-files.exit]
policy = "wait"
```

A layout, also TOML, references utilities by name and records arrangement plus argument policy:

```toml
[layout.project]
name = "project"

[[layout.project.items]]
utility = "project-files"
instance_policy = "per_window"
destination = "current_window"
argument_policy = "omit"

[[layout.project.items]]
utility = "logs"
instance_policy = "shared"
destination = "current_window"
argument_policy = "preset"
preset = "project-default"
```

Inspect the merged, effective configuration (defaults layered with definition and CLI overrides) without opening a file:

```sh
tum config show            # effective merged config
tum inspect --instance 8f31c2   # one instance's full record
tum list sessions          # home sessions the manager knows about
tum list panes             # panes, with managed/ordinary distinguished
```

Bash completion covers commands, definition names, instance IDs, and layout names — so `tum borrow <Tab>` offers the instances you can actually borrow, not every token in your shell history.

---

## Getting started

> tmux-borrow is a specified tool in phased implementation. The steps below describe the intended first-run path; package installation will arrive with the first implementation release. Track the `development/development-plan.md` phases to see exactly what's landed.

1. **Install the runtime deps:** tmux, Bash, SQLite, and a supported TOML parser. Optionally install `fzf` for fuzzy selection (the core CLI works without it — there's a numbered readline fallback).
2. **Run the wizard:** `tum setup` writes a minimal config and a private metadata directory, asking only for essentials (editor, selector preference, home-session policy, exit behavior).
3. **Check your environment:** `tum doctor` verifies dependencies and state-directory permissions.
4. **Register a utility:** `tum define add --wizard` (e.g. name `logs`, command `tail`, args `-F /var/log/syslog`).
5. **Start it:** `tum run logs` — it launches in its managed home window.
6. **Borrow it:** from a working window, `tum borrow --fzf`, pick `logs`, choose pane mode.
7. **Return it:** `tum return --fzf`.
8. **Wire one tmux key:** `bind-key u display-popup -E -w 80% -h 80% 'tum popup'` — the popup is the same commands, interactive.

That's the loop. Once it's muscle memory, the natural next steps are a couple of presets for the projects you switch between, one saved layout for your debugging/incident toolset, and a shell function or two that borrows a known instance by ID.

---

## What's next: the roadmap

The implementation plan moves in ten phases, each with a clear exit criterion, prioritized by requirement tier. The shape of what's coming:

| Phase            | Builds                                                                                  | Exit criterion                                                      |
| ---              | ---                                                                                     | ---                                                                 |
| Freeze decisions | tmux/SQLite versions, TOML parser, license, schema, command names, ID format, packaging | No undefined implementation decisions                               |
| Skeleton         | CLI dispatcher, help, dep checks, config discovery, completion skeleton                 | Help/status works; no tmux mutation                                 |
| Config & argv    | TOML validation, precedence, argv arrays, required prompts, presets, ad-hoc `--`        | Spaces/special chars, non-interactive failure, secret redaction     |
| Metadata         | SQLite schema/migrations, UUIDs, transactions, operation journal, listing               | Constraints, concurrency, interrupted transactions, migrations      |
| tmux adapter     | Home session/window, launch one utility, record IDs/PID, verify ownership, stop         | Failed launch cleans up only what it created                        |
| Borrow/return    | Pane borrow, host association, home placeholder, return, appearance snapshot            | PID preserved, location verified, rollback, external-move detection |
| Instances        | shared/per-window, auto-select, `--instance`, fzf, batch preflight                      | One-borrow-at-a-time                                                |
| Layouts          | Save-managed-only, incremental restore, argument persistence, separate-window           | Ordinary panes unchanged, prompts first, conflict behavior          |
| UI               | popup, fzf, readline fallback, wizard, tree view (if justified)                         | Popup delegates to CLI; cancellation is side-effect free            |
| release          | opt-in hooks, reconciliation, completion, diagnostics, ...                              | All P0 pass                                                         |

---

## Why you'll reach for this

You'll reach for tmux-borrow the day you realize how much of your terminal life is spent *re-establishing* tools you already had running — reconnecting to the same database, re-tailing the same log, re-navigating to the same directory in a fresh file manager — because tmux gave you no way to move the running thing to where you needed it. Once "borrow" exists, that whole class of friction collapses. The tool you wanted is already running; you just bring it over.

What makes it safe to actually adopt is the ownership model: the manager only ever moves panes it can prove it owns, never your editor or your shell, never with a shell-evaluated command line, never with a secret written to disk. What makes it safe to *script* is the Unix-style command surface with stable IDs, `--yes`, and `--format json` — so the same `tum borrow` you type at your desk is the one in your deploy-preflight check and your CI helper cluster. And what makes it safe to *trust* is the operation journal and `doctor`: every multi-step move is recorded, every crash is reconcilable, and "unknown" is a reported state rather than a silent guess.

If you keep tools running in tmux, tmux-borrow is the missing verb. The spec is detailed enough to script against today; the implementation is walking a deliberate, phased path to match it.

