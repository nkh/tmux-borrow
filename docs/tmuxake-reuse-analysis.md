# tmuxake — reuse analysis for tmux-borrow

This document does two things. First it answers the question that prompted it: can tmux-borrow do exactly what tmuxake does — attach a shell pane to any pane, hide it into another session, bring it back with a shortcut, and close it with a shortcut from either the side pane or the host pane? Then it lays out what is worth taking from tmuxake: ideas, architecture, and a few code snippets.

tmuxake is a single ~1340-line bash script (no deps beyond tmux and bash) by Nadim Khemir, the same author as tmux-borrow. It manages "side-panes" — a scratch shell bound to a host pane, stashed in a hidden session when not in use. It is the spiritual ancestor of tmux-borrow's borrow gesture, but narrower: one scratch shell per pane, no definitions, no layouts, no sqlite.

---

## Verdict: not exactly, and not with the same shortcuts

tmux-borrow reaches the same end states, but it does not offer tmuxake's one-key, context-aware flow. The two missing pieces are the toggle (one key that creates, shows, or hides) and the close-from-either-side (one key that works whether you are on the side pane or the host). tmux-borrow's borrow/return/stop are picker-based by design, which is right for the general case of many named instances but gets in the way of the spontaneous "give me a shell here" gesture.

| Behaviour                          | tmuxake       | tmux-borrow today                    | Same? |
| ---                                | ---           | ---                                  | ---   |
| Attach a shell to the current pane | prefix+Tab    | `tum run` a shell then `t b` (fzf)   | No    |
| Hide it into another session       | prefix+Tab    | `t r` returns it to its home session | Yes   |
| Bring it back with a shortcut      | prefix+Tab    | `t b` re-borrows (fzf); `t r` if one | No    |
| Close while on the side pane       | prefix+BSpace | `t s` / `t S` stop (fzf + confirm)   | No    |
| Close while host pane is active    | prefix+BSpace | same `t s` / `t S` (fzf + confirm)   | No    |

"Hiding into another session" is a yes only in effect: tmux-borrow returns a pane to its home session, which is a separate session, so the pane leaves the working window just as it does in tmuxake. The other four behaviours need more keys and a picker where tmuxake needs one. The honest summary: for the scratch-shell-with-shortcuts workflow, tmux-borrow today is a two-to-three-key, picker-mediated experience where tmuxake is a one-key toggle. Closing that gap is cheap and the second half of this document is mostly about how.

---

## How tmuxake works

A side-pane is an ordinary tmux pane running a shell, bound one-to-one to a "root-pane" (the host). The binding lives nowhere except in tmux itself: when a side-pane is hidden, it is `move-pane`'d into a window in a hidden session named `tmuxake`, and that window's *name* encodes the whole relationship — `<root_pid>-<side_pid>@<position><size>@<date>`. The window list of the `tmuxake` session is the entire state. There is no database, no config file, no marker on the pane.

Pane identity is by `pane_pid` (the shell's PID), which survives `move-pane` and `join-pane`, so a side-pane can be found again after it has been moved. Position and size are remembered in the encoded name and restored on show.

The commands that matter for the user's question:

- **toggle** — if the current pane has no side-pane, create one (split, default right at 60%, source a mini-prompt). If the side-pane is visible, hide it. If hidden, show it. One key, three outcomes, decided by current state.
- **close** — destroy the side-pane. Works from either pane: it checks "is the current pane a root with a side-pane" **or** "is the current pane itself a side-pane", and resolves the partner either way.
- **hide / show** — the two halves of toggle, available separately. Hide is `move-pane` into the `tmuxake` session; show is `join-pane` back, restoring recorded geometry.
- **detach / attach** — break the root↔side binding, name the side-pane, re-attach it later (to a different root pane). This is the generalised "move to another session and bring back."
- **import** — turn an ordinary tmux pane into a detached side-pane.
- **push / pop** — a one-slot stack: `push` detaches the current side-pane as `pushpop0`, `pop` (run in any session) attaches it. This is literally "push on a stack in one session, pop in another."
- **check / status / status2** — list side-panes, detect dead root or side PIDs (orphans), and emit glyphs for the bash prompt and tmux status bar.

---

## What to take from tmuxake

### Ideas

| Idea                              | Verdict | Why                                                                               |
| ---                               | ---     | ---                                                                               |
| One-key toggle (create/show/hide) | Adopt   | Biggest UX gap; collapses borrow+return+run into one key for the common case.     |
| Close from either side or host    | Adopt   | Answers the ask; stop resolves the instance tied to the active pane, no fzf.      |
| Geometry memory per host pane     | Adopt   | Remember size when hidden, restore on show, so the toggle lands right.            |
| Status glyphs (÷ § [ !)           | Adopt   | A concrete minimal prompt/status-bar design for the planned status segment.       |
| Orphan detection via kill -0      | Adopt   | Already planned as stale/host-closure detection; tmuxake's check is the hint.     |
| push/pop hand-off across sessions | Adopt   | Hand a borrowed pane to another window/session; a one-slot stack is a clean cut.  |
| import = adopt an existing pane   | Have    | `tum manage` is the same idea; borrow the move-pane + kill-placeholder pattern.   |
| Mini-prompt for scratch panes     | Adopt   | Sourcing a small prompt keeps a scratch shell uncluttered. Nice for scratch mode. |
| Window-name-as-state              | Skip    | Clever and zero-dep, but tmux-borrow chose sqlite + marker + verified pane id.    |
| Single shared stash session       | Skip    | Per-utility homes are richer (scope, instances); a stash only wins for scratch.   |
| PID-only pane identity            | Skip    | PIDs recycle after exit; tmux-borrow's verified-live-pane check is more robust.   |
| Env via show-env + send-keys      | Skip    | Fragile (keys spelled out to dodge quoting); tmux-borrow sets env at launch.      |

### Architecture

tmuxake's architecture is the opposite of tmux-borrow's, and the contrast is itself the lesson.

- **State in tmux itself.** The `tmuxake` session's window list is the database. No sqlite, no config, no files. Pro: nothing to corrupt, nothing to reconcile, survives a server restart as long as the session does. Con: no structured queries, no layouts, no argument presets — which is exactly why tmux-borrow outgrew it. tmux-borrow should keep its sqlite model and not regress.
- **Function-per-command, sourced-or-run.** The script doubles as a library (`USE_TMUXAKE_LIB` to source) and a CLI (`run_as_command` dispatches, `tmuxake-cleanup` unsets functions after). tmux-borrow's "small utilities with narrow responsibilities" plan is the same shape; tmuxake shows it works in a single file, but tmux-borrow's split into separate commands is healthier.
- **Pane introspection via formats.** Heavy use of `tmux display-message -p '#{pane_pid}'`, `#{pane_id}`, `#{pane_current_path}`, `#{pane_width}`, `#{pane_height}`. These are the right tmux-native primitives and tmux-borrow should use the same ones through its `tum-tmux` adapter.
- **Shape presets.** `r_shape="-h -p 60"`, `l_shape`/`t_shape`/`b_shape` derived. A compact way to encode split geometry; worth mirroring for tmux-borrow's split-direction work.
- **Zero deps.** No fzf, no sqlite. tmux-borrow has deliberately taken both as deps for power; tmuxake is a reminder that the scratch-toggle path should degrade gracefully when fzf is absent (the numbered fallback already covers this).

### Code worth quoting

These are the highest-value pieces. tmuxake's code has a few typos (for example `tmuxake-position-full-pane` writes `$pane-id` where it means `$pane_id`, and `tmuxake-detach` references `$detached_name` before it is assigned in one branch) — lift the patterns, not the lines verbatim.

**Close-from-either-side resolution.** This is the exact logic tmux-borrow's stop needs to borrow — decide whether the active pane is the root or the side, then resolve the partner. From `tmuxake-close`:

```bash
if pane_mirror_name=$(tmuxake-has-side-pane $pane_pid) || \
   pane_mirror_name=$(tmuxake-is-side-pane $pane_pid) ; then
    # current pane is a ROOT with a side-pane  ->  or  ->  current pane IS a side-pane
    ...
fi
```

`has-side-pane` matches windows named `<this_pid>-…` (I am a root); `is-side-pane` matches `…-<this_pid>` (I am a side). One guard, both cases. tmux-borrow would do the equivalent against its host-association record: "is the active pane a recorded host with a borrowed instance, or is it itself a borrowed instance?" and stop the resolved instance without an fzf pick.

**Geometry capture and restore.** Before hiding, grab the pane's size; on show, reapply it. From `tmuxake-hide` and `tmuxake-show`:

```bash
# capture before move
width=$(tmux display -p -t $side_pane_id '#{pane_width}')
height=$(tmux display -p -t $side_pane_id '#{pane_height}')
tmux move-pane -s $side_pane_id -t "$mirror:$pane_mirror_name"

# restore on show
[[ $size -ne 0 ]] && size="-l $size"
tmux join-pane $r_shape $size -s "$mirror:$pane_mirror_name"
```

tmux-borrow already records proportions in layouts; for a per-host-pane scratch toggle, the same capture-before-return / reapply-on-borrow keeps the pane landing right.

**Orphan check.** tmuxake's `check` walks the stash session and probes both PIDs. This is the concrete shape for tmux-borrow's planned stale-record detection:

```bash
! kill -0 $pane_pid      > /dev/null 2>&1 && echo "*root-pane process not running"
! kill -0 $side_pane_pid > /dev/null 2>&1 && echo "*side-pane process not running"
```

`kill -0` is the cheap "is this PID alive" probe. tmux-borrow would cross-check the recorded pane id against live tmux as well (PIDs recycle), but the liveness check is the right first filter.

**A tiny regex-capture helper.** tmuxake parses its encoded window names with a helper that declares regex groups into named globals. It is bash-specific and tmux-borrow will not need it (sqlite rows are already structured), but it is a neat idiom if any bash helper ever needs to parse a tmux format string:

```bash
parse_it() {
    parse_it_regex=$1; parse_it_string=$2; shift 2
    [[ $parse_it_string =~ $parse_it_regex ]] || return
    i=1
    for parse_it_name; do
        declare -g "$parse_it_name=${BASH_REMATCH[i++]}"
    done
}
```

**Status glyphs.** The scheme is small enough to copy wholesale into tmux-borrow's status segment: `÷` for a root pane (with a side), `§` for a side pane, `[` for a detached one, and a leading `!` when the partner is dead. A `status2` variant aggregates counts — `§ 4!1[2` reads "side pane, four healthy pairs, one orphaned, two detached." Compact and expressive.

---

## What to add to tmux-borrow to close the gap

Two additions would make tmux-borrow match the tmuxake workflow without giving up its instance model.

**A scratch toggle.** Define a built-in `scratch` utility (a shell, sourcing an optional mini-prompt) with `per_window` or per-host-pane scope, and bind one key — say `t o` — to a `tum scratch toggle` that does what tmuxake's toggle does: no instance for this host → run one and borrow it beside the active pane; visible → return it home; home → borrow it back, restoring recorded geometry. This reuses borrow/return/run unchanged; the new code is just the state check and the one-key binding. It keeps the picker out of the common case while leaving `t b` / `t r` for the many-instance case.

**A context-aware stop.** Extend `tum stop` (and a `tum scratch close` binding) so that when no instance is explicitly given, it resolves by context: if the active pane is itself a borrowed instance, stop that one; else if the active pane is a host with exactly one borrowed instance, stop that one; only fall back to fzf when ambiguous. Drop the confirm for the scratch variant (mirroring tmuxake's "everything in it is lost" contract) or keep it behind `t s` for general instances. This is the close-from-either-side behaviour the user asked for, and it falls out of the host-association record tmux-borrow already keeps.

With those two, the tmuxake flow — attach a shell, hide to another session, pop back, close from either side, all on single keys — is expressible in tmux-borrow, on top of the fuller instance/layout machinery that tmuxake never had.
