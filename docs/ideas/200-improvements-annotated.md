# tmux-borrow improvement ideas — annotated

## Instance management

### 1. Show definitions and instances in one listing

A single `tum list` that nests live instances under their
definitions, so one view answers both "what can I run?" and "what's running?".

### 2. Filter by definition, state, session, or workspace

Narrow the list to "all `borrowed` instances", "everything in
session `dev`", or "all `per_window` instances for this workspace window".

and labels (idea 3)

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

### 6. Restart a stopped instance with safe arguments

After an instance is `stopped`, bring it back using its
recorded definition and argv, re-prompting only for required/secret values that
were never persisted.

A stopped instance is currently dead metadata. Restart
lets users recover a familiar setup without re-deriving it, and exercises the
argument-collection path (secrets never stored → must re-prompt). It gives the
`wait` exit policy a graceful follow-up.

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

For each instance, display both its home (where it lives when
not borrowed) and its current (where it is now) location, in human-readable
session:window form.

what does it matter where it s borrowed from?

### 11. Detect stale records

Identify instance records whose recorded pane/PID no longer
match live tmux (process died unnoticed, server restarted, IDs reassigned) and
surface them as `stale`/`unknown` rather than letting the user act on bad data.

### 12. Export a definition as TOML

Emit a definition's resolved TOML block (command, args,
policy, hooks) so it can be copied into another machine's config or version
controlled.

### 13. Import a definition from TOML

The reverse of 12: accept a TOML block (pasted or from a
file), validate it, and register it as a new definition without manual editing.

### 14. Validate executable before launch

Before `tum run`, check the `command` path exists, is
executable, and is not a directory; fail early with a clear message instead of
launching a pane that immediately dies.

### 15. Warn about port/lock conflicts

When starting an instance of a utility known to bind a port
or take a lock, warn if the port/lock is already held (by another instance or an
unrelated process).

Done by a check function, not by the manager itself.

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

Can be ued to sort the list by recent activity, or to filter for "unused in the last N days".

### 20. Provide read-only status for scripts

A `tum status` (or `tum list --json`) that emits a stable,
documented, side-effect-free snapshot of all definitions/instances/layouts for
external scripts and status lines.

The CLI is meant to be scriptable (popup delegates to
it; `--instance` lets scripts pick). A frozen read-only schema is what makes
that contract durable. It is also the foundation for the optional status-line
(idea 181) and audit mode (151).

## Borrowing and tmux

### 21. Borrow beside active pane

The default borrow target: `join-pane` the utility into the
window containing the currently active pane, splitting beside it, and record
that active pane as the host.

split position is either utility set or a default that can be overwritten by a command-line option; where the command line can be started by a shortcut.

This is the headline interaction (use case #1: "borrow
a file manager beside the editor without restarting it"). The host association
it records is what later enables host-mediated moves (27) and return-by-host
(26). Without a sensible default, every borrow needs a target argument.

### 22. Borrow into a new window

Instead of splitting beside the active pane, create a fresh
window and move the utility pane there — for when the user wants the tool in its
own window, not crowded beside work.

Some tools (a full debugger, a wide log grid) are
unusable as a side split. Offering new-window borrow as a first-class target
covers that without forcing the user into manual tmux plumbing.

### 23. Choose target session/window

Let the user (or a script via `--target`) pick the exact
session and window a borrow lands in, not just "current".

Borrowing across sessions (idea 38) and scripted
layouts both need an explicit target. Without it the manager can only act on the
current window, which blocks automation and remote workflows.

### 24. Borrow several selected utilities

fzf multi-select several instances and borrow them in one
action — the batch-borrow use case (#13).

Restoring a working set one tool at a time is tedious;
batch borrow assembles a workspace in one pass. Crucially it forces the
"collect every required argument and resolve every conflict before the first
move" rule, so a mid-batch failure can roll back cleanly (idea 35).

Can borrow borrowed or at-home instances.

layout is driven by the utilities configuration or can be overridden by a command-line option.


### 25. Return active borrowed utility

A quick "send back the borrowed thing I'm looking at" —
return the instance whose pane is currently active, no selector needed.

The return gesture should be as cheap as the borrow.
Requiring the user to open a list and pick defeats the ergonomics goal; an
active-pane return is the natural inverse of borrow-beside-active (21).

Return can be initiated from the borrowed pane itself (a hotkey) or from the host.

### 26. Return utilities associated with host pane

Given a host pane, return every instance currently borrowed
beside it — the "clean up this window" gesture (use case #17).

The host association exists precisely so the manager
can answer "what did I borrow into this window?". Without a return-by-host, the
association is write-only metadata; this makes it useful for teardown.

If multiple borrowed panes are active (e.g. in a window with several borrowed tools), the return command should prompt for which ones to return.

### 27. Move host through manager and preserve association

When the user moves the *host* pane (e.g. to another window)
via a manager command, keep the borrowed utility associated with it rather than
orphaning the link.

tmux doesn't make a borrowed pane a child of its host
(terminology.md), so the association is the manager's to maintain. Preserving it
through manager-mediated moves is what makes host/return (26) reliable and is
explicitly required (FR-023).

### 28. Detect host closure

Notice when the host pane has been closed (window closed,
pane killed) while a borrowed instance is still associated with it, and flag the
instance's association as orphaned.

resource-ownership.md says: "If it disappears, mark the
association orphaned; do not guess a replacement based on position." Detection
is the prerequisite for that rule and for offering repair (29). Without it the
manager silently carries a dangling host ID.

### 29. Offer orphan repair choices

When an instance's host is gone (28), present explicit
options: return home, pick a new host, leave borrowed unassociated, or forget
the instance — never auto-guess.

This is the safe way to handle the dangling state:
explicit user choice over silent correction. It directly serves use case #19
("recover a borrowed pane after its home session was deleted") and the
principle "predictable moves".

### 30. Choose split direction

Let the user pick whether a borrow splits the host window
vertically or horizontally (and have a per-utility config).

### 31. Set initial split percentage

Control the size of the borrowed pane at split time (e.g. the
file manager takes 30%, not 50%), per-borrow or per-definition.

A 50/50 split wastes space for tools that need little
room and starves tools that need a lot. Setting it once per definition makes
every subsequent borrow land right.

### 33. Borrow complete managed window

The `window` borrow mode: move an entire managed home window
(session and all its panes) into a target session, instead of joining a single
pane.

Some utilities are themselves multi-pane (a window
with a server log + a tail + a prompt); moving them pane-by-pane breaks their
arrangement. Window borrow is a distinct, required operation (FR-022) and the
natural unit for "give me my whole monitoring dashboard over here".

* above implies that a managed window is a collection of managed panes, and that a managed pane is always part of a managed window, a session per window seems overkill *

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

### 38. Borrow across sessions

Allow a borrow whose source instance and target window live
in different tmux sessions (not just within the current session).

### 39. Restore home placeholder

While a pane is borrowed, keep an empty managed placeholder
pane in its home window; when the pane returns, put it back in place of the
placeholder, then remove the placeholder.

tmux-operating-model.md mandates this: "Keep a managed
empty home placeholder while the utility pane is borrowed… The placeholder must
never contain a user process." It preserves home-window geometry and gives a
deterministic return target instead of "append somewhere".

### 40. Detect external pane moves

Notice when a managed pane was moved by the *user* (via raw
tmux, not the manager) — e.g. the user `join-pane`d it elsewhere — and reconcile
the manager's record to match reality.

The architecture acknowledges external moves may need
reconciliation "on the next manager operation". Detecting them is what keeps the
manager's location columns trustworthy after the user does something manual.
Without it, the next borrow/return acts on stale coordinates.

## Layouts and workspaces

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

### 43. Restore each utility in own window

The `separate_window` destination mode: create one dedicated
manager-owned window per layout item, instead of crowding them into the current
window.

Some layouts (a full dev dashboard) are too big for
one window; some users prefer each tool in its own window. Offering both modes
(59) covers both workflows without forcing a choice at save time.

### 44. Clone layout for another project

Given a saved layout, produce a new layout record for a
different project — copying the structure but never moving the source's live
resources, and prompting for the new project's arguments.

Use case #11 ("clone a layout for another project,
reusing shared tools and creating local instances"). Cloning is what makes
layouts reusable across projects instead of one-shot. The "never move source"
rule is what makes it safe.

### 45. Reuse shared utilities during clone

When cloning, `shared`-policy items point at the *existing*
shared instance rather than spawning a duplicate — project-a and project-b
layouts both reference the one system monitor.

`shared` exists precisely so one instance serves many
windows; cloning that respects the policy avoids pointless duplicate processes
and keeps the shared instance's one-borrow-at-a-time guarantee intact.

### 46. Create per-window instances during clone

For `per_window`-policy items in a clone, create a fresh
instance bound to the destination project's working window, rather than reusing
the source's.

A `per_window` file manager rooted at project-a must
not be reused for project-b; cloning must spin up a new one rooted at the new
project. This is the policy-correct counterpart to 45 and the core of "creating
local instances" (use case #11).

### 47. Prompt for project arguments

During clone (and any restore with missing values), collect
all project-specific arguments up front, before any tmux mutation.

layouts.md and arguments.md both mandate collecting
every missing required value before changing tmux. Prompting first is what makes
"cancel leaves no state change" possible and lets a partial failure roll back
cleanly (56). It is the difference between a safe clone and a half-built one.

### 48. Save argument policy

When saving a layout, choose per-item how arguments are
stored: `omit` (default), `preset` (a named preset reference), or `values`
(explicitly approved non-secret values only).

This is FR-029 and the layouts "Saving arguments"
rule. It lets a layout be portable (omit), reproducible (preset), or
self-contained (values) without ever persisting a secret. The choice is per-item,
matching how users think about each tool.

### 49. Block secret values in layout

Refuse to write any argument marked secret (or any value
failing the secret-type check) into a layout, regardless of the chosen save
policy.

"Secret values are never stored" is a project-wide
invariant (arguments.md, metadata.md). Layouts are TOML on disk and easily
shared/committed, so they are the most dangerous place for a leak. A hard block
is the only safe default.

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

### 53. Preview layout contents

In the selector, show what a layout contains (which
utilities, which policies, what arguments are needed) before restoring it.

Restoring the wrong layout means adding/removing panes
you didn't want. A preview turns "is this the one?" into a glance, and surfaces
missing-argument prompts before the user commits.

The layout is in it's own window, so the preview can be a temporary window that is closed after the user makes a choice.

### 54. Validate all utilities before restore

Before restoring a layout, check every referenced definition
exists, its executable is valid (14), and no instance is already borrowed into a
conflicting spot — fail the whole restore up front if anything is wrong.

A layout restore touches many panes; failing halfway
leaves a half-built window. Validating everything first (the layouts.md "Resolve
all definitions, instances, conflicts… before changing tmux" rule) makes restore
all-or-nothing where possible.

### 55. Collect prompts before mutation

Gather every required argument prompt for a batch
borrow/restore *before* the first tmux change, so a cancel mid-prompt leaves
tmux untouched.

This is an explicit invariant ("Cancelled prompts
cause no state change") and a requirements rule (FR-010, arguments.md). It is
the single most important UX/safety property of batch operations and the
foundation for clean rollback (56).

### 57. Save managed-pane arrangement

When saving a layout, record the relative split arrangement
among the managed panes (a simple ordered split tree), so a restore can
reproduce it.

layouts.md says "The first version needs a simple
ordered split tree, not every possible tmux layout encoding." Recording
arrangement is what makes a restored layout *look* like the saved one, not just
contain the same tools.

### 58. Store optional size proportions

Alongside arrangement, optionally record the size proportion
of each managed pane (e.g. the file manager is 30%), to be reapplied on restore.

Proportions (not absolute cell counts) survive
different window sizes and make a restored layout immediately usable without
manual resizing. Optional, because some users want panes to fit available space.

### 59. Choose current or separate windows

A per-restore (not just per-save) choice between
`current_window` and `separate_window` destination modes, so the same layout can
be restored either way depending on context.

A layout saved for separate windows might still be
useful crammed into the current window for a quick task, and vice versa. Making
the destination a restore-time option doubles a layout's usefulness.

## Arguments and configuration

### 61. Prompt for required arguments

Before launch or borrow, if a required argument (declared in
the definition) has no value from any precedence source, prompt the user for it
in declaration order.

This is FR-010 and the arguments.md "Prompting" rule.
Required args without values are the most common reason a launch silently does
the wrong thing (e.g. a file manager with no root). Prompting makes the missing
value explicit instead of guessed.

can we use an external tool for this? intelli-shell, tldr, https://github.com/pindexis/marker, ...

### 62. Use argv arrays

Store and pass the executable's arguments as an ordered array
(`["-F", "/var/log/syslog"]`), never as a single shell command string.

This is FR-011 and a foundational principle ("no shell
re-parsing of arguments"). An array preserves spaces and special characters in
args (a path with spaces, a password-shaped value) and removes the entire class
of shell-injection bugs. It is the difference between safe and unsafe argv
handling.

### 65. Support non-echoing secret prompts

When prompting for a secret argument, read the value without
echoing it to the terminal (like `read -s`), and never store or log it.

Secrets (database passwords, API tokens) must be
supplied interactively or by a secret provider and never written to config/logs
(arguments.md). Non-echoing entry is the basic hygiene that makes interactive
secret entry safe, and it underpins the "secrets never persist" invariant.

### 66. Validate directory/file/integer arguments

For arguments declared with a type (`directory`, `file`,
`integer`), validate the supplied value before launch: a directory exists and is
readable, an integer parses, etc.

Catches "ranger /nonexistent" before it spawns a pane
that immediately errors, and catches typos in paths at the point where the error
message can name the offending argument. Also blocks the wrong type from
reaching the utility (defense in depth alongside 14).

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

### 69. Let layout preset override defaults

A layout item's selected preset overrides the definition's
default args, sitting below CLI override in precedence.

Completes the precedence chain (built-ins → global →
definition → layout/preset → CLI). A layout that says "use the project-a preset
for ranger" must beat the definition's generic default, or layouts can't
meaningfully customize.

### 70. Use -- for executable argv

In `tum run` and ad-hoc launch, everything after `--` is
passed verbatim as argv to the utility; manager options come before `--`.

This is the documented ad-hoc contract
(`tum run --name scratch --cwd "$PWD" -- /usr/bin/htop -d 10`, arguments.md).
`--` is the unambiguous separator that lets any utility flag through without
colliding with the manager's own options. It is what makes ad-hoc launch
possible at all.

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

This is FR-018. For users who don't want to edit TOML,
a wizard is the friendliest path to a correct definition. It also validates each
answer as it's given (66), catching errors earlier than template-editing.

### 75. Validate TOML before saving

Whenever config/layout is written (by editor exit, wizard, or
import), parse and schema-validate the TOML before committing it; refuse to save
invalid files.

An invalid config breaks every subsequent command.
Validating on save keeps the on-disk config always-loadable, gives the user an
immediate error at the source, and is the gate that makes template/wizard/import
safe. Development plan Phase 2 calls for it explicitly.

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

## Lifecycle

### 81. Keep utilities running at home by default

The default idle policy: a utility at home keeps running
rather than being suspended or killed when not borrowed.

lifecycle.md sets `keep_running` as the default and
explicitly warns against generic SIGSTOP/SIGCONT (arbitrary programs lose
connections, locks, state). Keeping the process alive is what makes "borrow a
*running* tool" work — there is no restart cost and no lost state. It is the
safe default; suspension is opt-in (85).

### 86. Configure wait/shell/close on exit

The exit policy: when the utility's process exits, choose
`wait` (leave the pane showing the exit result — default), `shell` (drop to a
shell in that pane), or `close` (close the pane).

This is FR-013. `wait` (the default) lets the user see
*why* a tool died; `shell` lets them poke around the corpse; `close` keeps home
clean. One knob covers all three common desires, per-utility.

### 87. Show exit status

When an instance stops, record and display the process exit
status (code / signal), alongside the stopped state.

"Why did my monitor die?" is unanswerable without the
exit status. Recording it turns a `stopped` row into a diagnosable event and
feeds lifecycle diagnostics (100). Cheap — capture on the wait/exit path.

### 88. Restart stopped instance

Bring a `stopped` instance back up — same definition, fresh
process — reusing the recorded argv and re-prompting for non-persisted required
args.

This is the lighter sibling of idea 6 (which framed it
as "restart with safe arguments"). A dead monitor shouldn't require re-registering
or re-deriving args; restart makes recovery one command. It also gives `wait`/exit
a clear next step.

### 92. Refresh utility before borrow

Before borrowing, optionally refresh the utility's view (e.g.
a file manager re-reads the directory, a log viewer seeks to latest) so the
borrowed pane shows current state, not stale state from when it sat idle.

A tool that sat at home for an hour shows stale data;
borrowing it beside active work and seeing an hour-old directory is jarring.
Refresh (via the resume hook, 83, or a dedicated signal) makes the borrowed pane
immediately useful.

### 95. Confirm explicit stop

`tum stop` requires confirmation unless `--yes`, because
stopping kills a running process the user may not want to lose.

lifecycle.md: "Require confirmation unless `--yes`."
A stop is destructive (the running utility's state is lost) and irreversible;
confirmation is the basic guardrail. `--yes` keeps it scriptable.

### 98. Keep failed utility pane visible

When a utility fails (crashes, hook fails, launch fails), do
not auto-close the pane — leave it visible so the user can read the error.

Auto-closing a failed pane hides the very information
needed to debug it. Leaving it visible (with the `failed` state) turns a crash
into a diagnosable event and matches `wait`'s philosophy applied to failures.
architecture.md's failure handling implies inspectable failure states.

## UI and navigation

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

### 104. Numbered selector without fzf

When fzf isn't installed, present a numbered readline menu
(type the number to pick) so the CLI is fully usable without fzf.

interaction-design.md: "The core CLI must work without
fzf." fzf is optional (research/plugin-analysis.md), so a no-fzf fallback keeps
the tool usable on minimal systems and in CI. The numbered menu is the simplest
fallback that handles single selection.

### 106. Show home/current location in preview

In fzf's preview pane, show the selected instance's home and
current location (and maybe a pane preview), so the user can confirm before
acting.

The row (105) is compact by necessity; the preview is
where the detail goes. Seeing "home: dev:3, current: proj-a:1" before borrowing
prevents the wrong-target borrow. Pairs with the location columns (10).

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

### 110. Complete definition and layout names

Complete the *arguments* too: `tum run <Tab>` offers
definition names; `tum layout restore <Tab>` offers layout names.

Names are the primary identifiers users type; without
their completion, users guess and mistype. This is the higher-value half of 109
— completing flags is easy, completing the right entity names is what actually
saves typing. FR-027 lists "definitions, instances, layouts".

### 111. Tree view of sessions/windows/instances

An optional hierarchical view (sessions → windows →
instances) showing where every managed instance currently lives.

This is FR-028 (P2). A tree makes the "what's where"
question answerable at a glance and helps spot borrowed instances scattered
across sessions. Pairs with the per-window/workspace model.

### 113. JSON output for scripts

A `--format json` option on list/status commands emitting a
stable, documented JSON shape for scripts to consume.

command-index.md lists `--format table|json` as
common. JSON is the lingua franca for shell pipelines, status lines (181), and
external tools. Without a stable shape, scripts break on every release. This is
the structured form of idea 20.

### 114. Concise and verbose listings

A `--verbose` (or `-v`) toggle controlling how much each row
shows: concise by default, verbose adds home/current, uptime, last borrow, etc.

One list command serving both "quick glance" and
"deep inspection" avoids a separate command per detail level. The concise form
keeps the default readable; verbose pulls in the columns from 10, 18, 19 without
a new command.

### 115. Support non-interactive mode

Every command works with no TTY: prompts become errors
listing missing values, selectors require `--instance`/`--name`, no fzf.

arguments.md mandates this for prompts; the broader
principle is scriptability. A command that hangs waiting for input in a script is
broken; non-interactive mode makes the CLI safe in cron, hooks, and pipelines.

### 117. Clear conflict messages

When a borrow/restore hits a conflict (instance already
borrowed, target too small, definition missing), emit a single clear message
naming the instance, the conflict, and the suggested fix.

interaction-design.md calls for "Clear conflict
messages". Vague errors ("operation failed") force the user to dig; a precise
one ("ranger#2f0d is already borrowed into proj-a:1 — return it first or choose
another instance") lets them act immediately. Cheap and high-impact for support.

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

## Metadata and recovery

### 121. UUIDs for durable objects

Generate and store UUIDs as the primary keys for definitions,
instances, layouts, and working-window records — never use tmux IDs or display
names as keys.

metadata.md is explicit: tmux IDs (`$N`, `@N`, `%N`)
are runtime-only and change on restart/recreation; display names aren't unique.
UUIDs are the only durable identity, and they underpin every ownership check
("a matching instance record" — resource-ownership.md). Without them, recovery
and clone are impossible to do safely.

### 123. SQLite transactions

Use SQLite transactions (`BEGIN IMMEDIATE` for state changes)
for all metadata writes, so a partial update can't leave the DB inconsistent.

metadata.md mandates this. A borrow touches several
columns (state, current location, host association); without a transaction a
crash mid-write leaves the record half-borrowed. Transactions give all-or-nothing
metadata updates, the precondition for safe rollback (56) and reconciliation
(125).

### 130. Detect concurrent operations

Notice when two manager processes try to operate on the same
instance simultaneously and serialize or refuse one.

Two `tum borrow` for the same instance racing would
violate "one active borrow per instance". Detection (beyond SQLite row locking)
lets the manager report the conflict by name (117) rather than relying on the
user to interpret a lock error. Pairs with the transaction discipline (123).

## Safety and security

### 141. Never persist secret args

Secret-typed argument values are never written to config,
layouts, the DB, operation payloads, or logs — only held in memory for the
process's argv.

This is the project's strongest safety invariant
(arguments.md, metadata.md, testing-strategy). Secrets in TOML/DB/logs get
committed, backed up, and pasted into bug reports. Never-persist is the only
rule that holds across all storage locations; everything else (65, 80, 49) is
enforcement of it.

### 155. Handle missing executables clearly

When a utility's `command` is missing or not executable, give
a named, actionable error ("definition `logs` command `/usr/bin/tail` not found
— install it or fix the definition") rather than a generic launch failure.

Missing executables are the most common launch failure
(renamed binary, different machine, not installed). A clear error names the
culprit definition and path so the user can fix it in one step; a generic failure
sends them digging. Cheap UX win on top of 14's validation.

### 159. Require explicit force-stop

A normal `stop` uses graceful-then-force (96) within a bounded
time; an *immediate* force-kill (`SIGKILL` with no grace) requires an explicit
`--force` flag.

A force-kill skips the graceful window (96), losing any
unsaved state. Making it explicit prevents an accidental force-kill (a default
that's too aggressive) while keeping it available when a utility is truly stuck.
Matches the "safe defaults" principle and the confirmation discipline (95).

## Developer experience

### 161. Small independent command modules

Implement each command (`tum-borrow`, `tum-return`,
`tum-layout`, …) as a small, independently callable program behind a thin `tum`
dispatcher, rather than one monolithic script.

architecture.md proposes exactly this component split.
Small modules are individually testable, replaceable, and scriptable (a power
user can call `tum-state` directly). It also matches the Unix-style principle in
the README. The dispatcher stays trivial, so logic doesn't accrete in one place.

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

### 166. Use ordinary panes as adversarial fixtures

In tests, create ordinary (non-managed) panes alongside
managed ones and assert their IDs, commands, and locations are unchanged after
every manager operation.

testing-strategy: "Tests must create ordinary panes as
adversarial fixtures and verify their IDs, commands, and locations remain
unchanged." This directly tests the cardinal rule (never move/kill/resize an
ordinary pane). Without adversarial fixtures, a regression that nudges an
ordinary pane ships unnoticed.

### 180. Contribution guide

A `CONTRIBUTING.md` covering the dev setup, the test layers
(165–170), the docs checks (171–173), the component boundaries (161–163), and
the safety invariants contributors must not break.

dev plan Phase 10 lists "Contribution guide". The
project has unusual, hard constraints (never touch ordinary panes, argv not
shell strings, secrets never persisted); a guide fronts these so contributors
don't learn them via a rejected PR. Also sets up the test/docs checks as
expected, not optional.

## Future extensions

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

siplest is to that the utility is a script that cecs and then starts a command

