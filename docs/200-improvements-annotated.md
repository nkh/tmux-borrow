# tmux-borrow improvement ideas — annotated

## Instance management

### 1. Show definitions and instances in one listing

A single `tum list` that nests live instances under their
definitions, so one view answers both "what can I run?" and "what's running?".

### 2. Filter by definition, state, session, or workspace

Narrow the list to "all `borrowed` instances", "everything in
session `dev`", or "all `per_window` instances for this workspace window".

and filter on labels too (idea 3)

### 3. Assign labels to instances

Free-form tags on an instance (`prod`, `scratch`,
`debug-repro`) independent of its definition, to mark *why* this particular copy
exists.

Definitions already carry categories (idea 9); labels
on instances answer the orthogonal question "which of these five `ranger`
copies is the one tied to the incident?". Useful for ad-hoc instances that have
no meaningful name.

### 5. Start another instance from a definition

From the instance list, launch a second copy of the same
definition (a second `ranger` rooted elsewhere) without retyping the name.

### 7. Pin frequently used instances

Mark instances as pinned so they sort to the top of lists,
survive "hide inactive" filters, and are never swept by cleanup.

### 8. Hide definitions from quick-borrow list

Mark some definitions as hidden so they don't appear in
`tum borrow --fzf`, while still launchable explicitly by name (rarely-used
tools, or definitions that exist only as layout members).

### 9. Group definitions by category

Tag each definition with a category (`monitor`, `files`,
`db`, `repl`) and let the selector group or filter by it.

### 10. Show home and current locations

For each instance, display its current (where it is now) location, in human-readable
session:window form.

### 11. Detect stale records

Identify instance records whose recorded pane/PID no longer
match live tmux (process died unnoticed, server restarted, IDs reassigned) and
surface them as `stale`/`unknown` rather than letting the user act on bad data.

### 14. Validate executable before launch

Before `tum run`, check the `command` path exists, is
executable, and is not a directory; fail early with a clear message instead of
launching a pane that immediately dies.

### 17. Label instances by project

Automatically tag each instance with the project/workspace it
was borrowed for or launched from, so lists can answer "which utilities belong
to project-a?".

Overlaps with idea 3 (manual labels) but is automatic
and ties to the `workspace_window` record. It makes layout/clone (41–60) and
cleanup ("abandon project-a, reap its instances") natural.


### 18. Show uptime

Display how long each instance's process has been running,
alongside state.

Uptime tells you whether a "home" instance is actually
the long-lived one you expected or a fresh restart you didn't notice. Cheap —
derivable from PID start time — and it makes the lifecycle states more
trustworthy at a glance.

### 19. Show last borrow/return time

Per instance, a timestamp of its most recent borrow and most
recent return.

Helps answer "is anyone actually using this shared
instance?" and supports stale detection (an instance not borrowed in weeks is a
reap candidate). Cheap to store on the existing `updated_at`-style columns.

Can be used to sort the list by recent activity, or to filter for "unused in the last N days".

### 28. Detect host closure

Notice when the host pane has been closed (window closed,
pane killed) while a borrowed instance is still associated with it, and flag the
instance's association as orphaned.

### 30. Choose split direction

Let the user pick whether a borrow splits the host window
vertically or horizontally (and have a per-utility config).

### 31. Set initial split percentage

Control the size of the borrowed pane at split time (e.g. the
file manager takes 30%, not 50%), per-borrow or per-definition.

A 50/50 split wastes space for tools that need little
room and starves tools that need a lot. Setting it once per definition makes
every subsequent borrow land right.

### 35. Warn when destination is too small

If the target window is too narrow/short for the borrowed
pane to be usable (e.g. a 20-column window can't show a file manager), warn or
refuse rather than produce a tiny broken pane.

### 36. make current pane a managed utility

A `tum manage` command that takes the currently active pane and registers it as a managed utility, so it can be borrowed/returned like any other.
creates a definition and instance record for the pane, using its current command and arguments.


### 37. Select target window with fzf

When a target is needed, list candidate sessions/windows in
fzf (with live panes previewed) so the user can pick visually instead of typing
a name.

Window names are forgettable and non-unique (IDs are
the real keys — terminology.md). An fzf picker with a preview turns "borrow into
that one project window" into a glance-and-select.

### 41. Save only managed panes

When saving a layout, record only the manager-owned utility
panes and their arrangement — never ordinary user panes, their contents, sizes,
or identities.

This is the defining property of a layout
(terminology.md) and a hard requirement (FR-014). It is also a safety invariant
("Layouts never claim ordinary panes"). Without it, a restore would overwrite
the user's actual work — the cardinal sin this project exists to avoid.

### 42. Restore into current window

The `current_window` destination mode: add the layout's
managed panes into the window the user is already in, alongside whatever
ordinary panes are there.

This is the common restore gesture ("give me my tools
here"). It must add panes incrementally without applying a whole-window
`select-layout` that would resize the user's existing panes (layouts.md
"Restore").

### 44. Clone layout for another project

Given a saved layout, produce a new layout record for a
different project — copying the structure but never moving the source's live
resources, and prompting for the new project's arguments.

Use case #11 ("clone a layout for another project,
reusing shared tools and creating local instances"). Cloning is what makes
layouts reusable across projects instead of one-shot. The "never move source"
rule is what makes it safe.

### 50. Name and describe layouts

Give each layout a human name and an optional free-text
description, shown in the layout list and selector.

Layout names are how users invoke `tum layout restore
NAME`; a description ("project-a morning setup") disambiguates similar layouts.
Cheap and removes the "which layout was that?" guess.

### 51. Tag layouts by project type

Tag layouts (`web`, `data`, `ops`) so the selector can filter
"show me layouts that fit this kind of project".

Same scaling argument as definition categories (9),
applied to layouts. Pairs with project-root discovery (195) to suggest the right
layouts automatically.

### 52. Sort layouts by recent use

Order the layout list/selector by most-recently-restored
first, so the layout you used this morning is at the top.

Recency beats alphabetical for the selector's purpose
(pick the one you probably want). Trivial to store (a `last_used_at` column on
`layout`).

### 55. Collect prompts before mutation

Gather every required argument prompt for a batch
borrow/restore *before* the first tmux change, so a cancel mid-prompt leaves
tmux untouched.

This is an explicit invariant ("Cancelled prompts
cause no state change") and a requirements rule (FR-010, arguments.md). It is
the single most important UX/safety property of batch operations and the
foundation for clean rollback (56).

### 58. Store optional size proportions

Alongside arrangement, optionally record the size proportion
of each managed pane (e.g. the file manager is 30%), to be reapplied on restore.

Proportions (not absolute cell counts) survive
different window sizes and make a restored layout immediately usable without
manual resizing. Optional, because some users want panes to fit available space.

### 65. Support non-echoing secret prompts

When prompting for a secret argument, read the value without
echoing it to the terminal (like `read -s`), and never store or log it.

Secrets (database passwords, API tokens) must be
supplied interactively or by a secret provider and never written to config/logs
(arguments.md). Non-echoing entry is the basic hygiene that makes interactive
secret entry safe, and it underpins the "secrets never persist" invariant.

### 67. Set optional argument defaults

Let a definition supply default values for optional arguments,
used when no higher-precedence source provides one.

Most utilities have sensible defaults (`tail -n 200`);
encoding them in the definition means `tum run logs` just works, and the default

### 68. Let CLI override definition defaults

Command-line arguments (after `--`, or via named options)
override the definition's defaults, per the documented precedence chain.

This is half of the precedence rule (arguments.md:
CLI override is highest) and the basis of ad-hoc launch (FR-003). Without it
every variation needs a new definition, defeating the point of defaults.

### 71. Ad-hoc launch supports manager options

An ad-hoc launch (`tum run -- ...`) can still take manager
options before `--` (`--name`, `--cwd`, `--instance-policy`), defaulting the
rest from config.

arguments.md: "Unspecified manager options use
configured defaults." Ad-hoc doesn't mean unmanaged — an ad-hoc utility can be
assigned to a session and managed like a registered one (overview.md). Letting
it take options is what makes that true.

### 72. Open config in editor

`tum config edit` opens the main TOML config in `$EDITOR`,
so users never need to know the file path.

This is FR-016. Knowing where XDG-state vs config
lives is exactly the kind of friction the manager should hide. Opening through
`$EDITOR` also respects the user's chosen editor and lets the manager re-validate
on save (75).

### 73. Append commented definition template

`tum define add --template` appends a commented-out
definition block to the config, which the user fills in and uncomments.

This is FR-018. A template gives users a correct
skeleton (right keys, right types) to edit, instead of forcing them to remember
the schema. The commented form means a half-filled template never breaks the
config.

### 74. Provide readline wizard

`tum define add --wizard` asks a series of readline questions
(name, command, args, policy…) and writes a definition from the answers.

### 77. Detect unknown config keys

On validation, warn (or error) on config keys not in the
schema — catches typos like `instnace_policy` that silently do nothing.

A typo'd key is indistinguishable from "no setting"
without detection, leading to baffling behavior. Unknown-key detection turns a
silent misconfiguration into an immediate, locatable error. This is standard
hygiene for any typed config.

### 79. Support per-utility environment

A definition can declare a key/value environment map applied
to that utility's process at launch (e.g. `PAGER=cat` for one tool).

Some utilities need env tweaks incompatible with the
user's global env; a per-utility map keeps the override scoped and reproducible
across instances of that definition. The data model already lists `environment`
(architecture.md).

### 101. One compact popup entry point

A single `tum popup` (opened by one tmux binding) presenting a
compact action list: borrow, return, manage, start, restore/save layout, edit
config, diagnostics.

interaction-design.md mandates this. One entry point
beats a sprawl of bindings (idea 108); the popup is "the control surface for
utility and layout selection, not a new set of tmux navigation keys". Each action
delegates to the same CLI command used in scripts, so the UI adds no logic.

### 102. fzf searchable selector

Use fzf as the primary searchable selector for instances,
definitions, and layouts when it is installed.

FR-009 and interaction-design.md. With dozens of
instances, type-to-filter is far faster than scrolling. fzf is the de-facto
standard, optional, and the project already treats it as the primary backend
(research/plugin-analysis.md). Make it optional — the core CLI works without it.

### 103. fzf multi-select only for batch-safe actions

Allow fzf multi-selection (Tab) only for actions that are
safe to apply to many items at once (batch borrow, batch return); never for
destructive singletons.

interaction-design.md: "Enable multi-select only for
batch-safe actions." Multi-select on `stop` or `remove` would make one stray Tab
wipe several running utilities. Restricting it to batch-borrow/return keeps the
footgun closed while preserving the productivity of batch borrow (24).

### 107. Configure popup dimensions

Let the user set the popup's width/height (or a percentage of
the window) so it fits their terminal and preference.

A fixed-size popup is too small on a big monitor and
too big on a laptop; a percentage-based default with an override fits both. Cheap
and removes a common "I can't see my list" annoyance.

### 108. Keep tmux bindings minimal

Ship one (configurable) tmux binding that opens the popup;
do not bind every action to its own key.

interaction-design.md and architecture.md both insist
on this. A large key map pollutes the user's tmux config and conflicts with their
existing bindings; one popup binding is unobtrusive and the popup contains all
actions. It keeps the manager "a small orchestration layer", not a key-binding
takeover.

### 109. Bash completion

Tab completion for `tum` subcommands and their options, so
the user doesn't memorize the command index.

FR-027. Completion is the difference between a CLI
that's pleasant in scripts and one that isn't. It also keeps the option names
honest: if completion lags the real options, users hit it immediately.

### 119. Help topic per command

`tum <command> --help` (and `tum help <command>`) giving a
focused help page per subcommand, not just a global dump.

The command index is large (command-index.md); a
global help can't usefully explain each subcommand's options. Per-command help is
the standard CLI expectation and the basis for the docs/examples consistency
checks (173). Generate it from metadata (164) to avoid drift.

### 120. Align popup actions with CLI

Every action offered in the popup maps 1:1 to a CLI
subcommand with the same options — no popup-only or CLI-only behavior.

architecture.md and interaction-design.md both require
the popup to delegate to CLI commands. Alignment means anything doable in the UI
is scriptable, and a bug fix in the CLI fixes the UI too. It also keeps the
interactive surface from growing its own dialect.

### 162. Single tmux adapter

All tmux interaction goes through one `tum-tmux` module
(wrapping `new-session`, `join-pane`, `move-window`, …), so the rest of the code
never calls `tmux` directly.

architecture.md lists `tum-tmux` as a component. A
single adapter means tmux-version quirks, quoting, and ID verification happen in
one place; every other module reasons about a clean interface. It also makes the
isolated-server tests (165) and failure injection (168) tractable — you mock one
boundary.

### 163. Single state access layer

All metadata read/write goes through one `tum-state` module
(`list`/`get`/`put`/`delete`/`recover`), so transactions, locking, and schema
rules live in one place.

architecture.md's `tum-state` component. Centralizing
state access means the transaction discipline (123), FK enforcement (126), and
reconciliation (125) are implemented once, not re-implemented (or missed) in each
command. It's the data-side counterpart to the tmux adapter (162).

### 165. Test isolated tmux server

tmux integration tests run against a private server socket
(`tmux -L tum-test -f /dev/null`), never the user's default server.

testing-strategy invariant: "Never use the user's
default tmux server." Tests must be able to create/destroy panes freely without
risking the user's real session; an isolated server makes the suite safe to run
on a developer's live machine and makes tests deterministic (no interference
from the user's windows).
### 181. Optional status-line summary

An opt-in tmux status-line segment showing a compact manager
summary (e.g. "2 borrowed", or the active window's borrowed utilities).

A status line makes the borrow state ambient — you see
at a glance what's borrowed where without opening a popup. Builds on the
read-only status (20). Opt-in because status lines are personal and crowded;
don't impose on users who don't want it.

### 193. Named environment profiles

Named, switchable sets of environment variables (e.g. `dev`,
`staging`, `prod`) that a utility can be launched with, beyond the per-utility
env (79).

A DB console wants different creds per environment;
profiles let the user switch the whole env set without editing the definition.
Builds on per-utility env (79) with a reusable, named layer. Secrets in a profile
must still go through the secret provider (65/141), never the profile file.

### 194. Workspace detection from cwd

Infer the current "workspace" (project) from the shell's
current working directory, so per-window instances and layouts auto-associate
without explicit naming.

The `per_window` policy and project layouts both need
a workspace identity; deriving it from cwd means the user doesn't have to declare
it. This is the input to automatic layout suggestion and to project labels (17).
Powers the "right tools for this project" experience.

simplest is to that the utility is a script that checs and then starts a command

