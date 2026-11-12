#!/usr/bin/env python3
# scripts/gen_manpages.py — bootstrap the per-command manpage *sources* in man/.
#
# These .md files are the CANONICAL source for two things at once:
#   1. `make man` renders them to man/tum-<cmd>.1 (pandoc, or scripts/md2man.awk).
#   2. `tum <cmd> --help` extracts the SYNOPSIS and EXAMPLES sections from them
#      (awk), so help text and the manpage never drift.
#
# This script BOOTSTRAPS the files so they all exist with a consistent shape.
# After bootstrapping, edit the .md files directly in man/ — do not regenerate
# over hand edits. Re-run only to recreate a deleted file.
#
# Markdown convention (matches man/tum.1.md and what scripts/md2man.awk parses):
#   YAML front matter (title / section / header) -> .TH
#   ## SECTION (H2)  -> .SH
#   - bullet         -> .IP \(bu 2
#   ``` fenced code  -> .nf / .fi
#   **bold** / *ital* rendered by pandoc; md2man.awk passes them through.

import os
from textwrap import dedent

MAN_DIR = os.path.join(os.path.dirname(__file__), "..", "man")
MAN_DIR = os.path.abspath(MAN_DIR)

HEADER = "tmux-borrow Manual"

# Per-command content. `desc` is a list of paragraphs; `examples` is the raw
# fenced-code content (a comment per line explaining the invocation).
COMMANDS = [
    dict(
        name="borrow",
        purpose="attach a utility or layout beside the host pane",
        synopsis=[
            "**tum borrow** [*util*|*layout*]",
            "**tum borrow** **-h** | **--help**",
        ],
        desc=[
            "Attach a utility (or layout) instance beside the current host pane, "
            "creating it first if none exists to reuse. Borrowing moves a pane with "
            "`join-pane`/`move-pane` \u2014 the process is moved, not restarted, so its "
            "state is preserved.",

            "Default-mode resolution order: (1) an instance already bound to this "
            "host is re-shown; (2) else a hidden instance of this utility is "
            "borrowed (the chooser picks if several \u2014 pool instances are always "
            "available, owned instances only to their home host); (3) else a new "
            "**pool** instance is created and borrowed. An orphan whose host is dead "
            "counts as hidden here; re-borrowing clears the dead binding.",

            "With no argument, the chooser opens over every utility and layout. "
            "Picking an instantiated one borrows that instance; picking an "
            "uninstantiated one creates and borrows it. Borrowing a layout borrows "
            "all its members into the host window at their declared positions.",
        ],
        examples=[
            "tum borrow htop          # reuse a hidden instance, else create a pool one",
            "tum borrow               # chooser over all utilities and layouts",
            "tum borrow dev           # borrow the 'dev' layout (all members attach)",
        ],
        see_also=["tum-new", "tum-flip", "tum-close", "tum-defs", "tum-keymap"],
    ),
    dict(
        name="new",
        purpose="create a fresh owned instance and borrow it",
        synopsis=[
            "**tum new** [*util*|*layout*]",
            "**tum new** **-h** | **--help**",
        ],
        desc=[
            "Always create a fresh instance owned by the current host pane (its "
            "`home` is set to this pane), then borrow it. It is a sibling of "
            "**tum borrow** that skips the reuse-hidden branch: where `borrow` "
            "reuses first, `new` always creates.",

            "An owned instance flip-flops back only to its home pane after a hide; "
            "another host cannot take it by name. To move an owned instance "
            "elsewhere, that host must pick it explicitly from the no-name chooser, "
            "which re-homes it. This is the project-file-manager case: a `ranger` "
            "that belongs to one window.",

            "With no argument, the chooser opens over all utilities and layouts; "
            "every pick creates a fresh owned instance, whether or not one already "
            "exists. On a layout, every member is created fresh and owned.",
        ],
        examples=[
            "tum new ranger           # an owned ranger for this window",
            "tum new                  # chooser over all; every pick creates a fresh owned instance",
            "tum new debug            # create a fresh owned 'debug' layout group",
        ],
        see_also=["tum-borrow", "tum-flip", "tum-defs"],
    ),
    dict(
        name="flip",
        purpose="hide or show a borrowed thing by slot, or context-aware",
        synopsis=[
            "**tum flip** [*slot*]",
            "**tum flip** **-h** | **--help**",
        ],
        desc=[
            "Toggle a borrowed thing between shown and hidden. With a *slot* "
            "(a single character in `0\u20139` or `a\u2013z`), toggle the thing bound to "
            "that slot in the current host window. Hide parks the pane in the "
            "hidden session (clears `host`, captures geometry); show brings it "
            "back beside its host and restores the recorded geometry.",

            "With no slot, **tum flip** is context-aware: from a focused borrowed "
            "pane it toggles just that pane; from a host with one borrowed thing "
            "it toggles that; from a host with several it opens the chooser. An "
            "owned utility flipped back from hidden returns only to its home pane; "
            "a flip from another pane does nothing to it.",

            "A layout's slot toggles **all** its members as a group: a group hide "
            "hides every member (including any individually shown); a group show "
            "shows every member (including any individually hidden). A member's "
            "own slot toggles just that member, which a later group show brings "
            "back. The process is never restarted \u2014 only moved.",
        ],
        examples=[
            "tum flip 1               # hide or show the thing in slot 1",
            "tum flip                 # context-aware: focused pane, or host's single, or chooser",
            "tum flip d               # toggle the whole 'dev' layout group",
        ],
        see_also=["tum-close", "tum-push", "tum-keymap"],
    ),
    dict(
        name="close",
        purpose="kill the focused borrowed pane (context-aware)",
        synopsis=[
            "**tum close**",
            "**tum close** **-h** | **--help**",
        ],
        desc=[
            "Destroy the focused borrowed pane with `kill-pane`. The pane and all "
            "its state are gone; there is no cleanup and no confirmation \u2014 close "
            "is immediate, mirroring tmuxake.",

            "Close is context-aware, sharing the target resolver with **tum flip** "
            "and **tum push**: if the focused pane is itself borrowed, close it; if "
            "the focused pane is a host with one borrowed thing, close that; if it "
            "is a host with several, open the chooser and close the selection.",

            "Close works inside a layout: a closed member is gone from the group "
            "and the remaining members continue with their layout id unchanged. "
            "There is no layout instance to repair \u2014 the layout is just an id "
            "stamped on member panes. Close is destructive; to park a pane without "
            "destroying it, use **tum flip** instead.",
        ],
        examples=[
            "tum close                # focused borrowed pane, or host's single, or chooser-pick",
            "# bound to  t x  in the shipped tum-bindings.conf (see tum-keymap(5))",
        ],
        see_also=["tum-flip", "tum-push", "tum-keymap"],
    ),
    dict(
        name="push",
        purpose="detach a borrowed pane onto the LIFO stack",
        synopsis=[
            "**tum push**",
            "**tum push** **-h** | **--help**",
        ],
        desc=[
            "Detach the focused borrowed pane onto a LIFO stack. The pane parks in "
            "the hidden session with no host; its geometry is recorded and a push "
            "sequence number is stamped on its state. Push is how you hand a "
            "utility to another session: push here, **tum pop** there.",

            "Push is context-aware like **tum flip** and **tum close**: from a "
            "focused borrowed pane it pushes that pane; from a host with one "
            "borrowed thing it pushes that; from a host with several it opens the "
            "chooser.",

            "Push is independent of the pool/owned distinction \u2014 `home` is "
            "untouched, and a pushed pane attaches to whoever pops it. A pushed "
            "pane has no host and is **not** reachable by **tum flip**; bring it "
            "back only with **tum pop**. Non-contiguous sequence numbers are fine, "
            "since panes may be closed between pushes.",
        ],
        examples=[
            "tum push                 # focused borrowed pane (or host's single) onto the stack",
            "# bound to  t p  in the shipped tum-bindings.conf",
            "# then in another session:  tum pop",
        ],
        see_also=["tum-pop", "tum-flip", "tum-close"],
    ),
    dict(
        name="pop",
        purpose="attach the top of the push stack to the current host",
        synopsis=[
            "**tum pop**",
            "**tum pop** **-h** | **--help**",
        ],
        desc=[
            "Attach the highest-push pane from the stack to the current host pane, "
            "at the geometry recorded when it was pushed. The pane is consumed "
            "from the stack \u2014 its push field is cleared and its host is set to "
            "the current pane.",

            "The stack is `list-panes -a` filtered to panes whose state carries a "
            "`push` field, sorted by push value descending, so **tum pop** is LIFO: "
            "the last thing pushed is the first thing popped. Push several "
            "utilities from anywhere, then pop them one by one to assemble a "
            "working set \u2014 no layout file needed.",

            "Pop is independent of pool/owned: `home` is untouched. If the stack "
            "is empty, pop does nothing.",
        ],
        examples=[
            "tum pop                  # attach the most-recently-pushed pane here, at its geometry",
            "# bound to  t P  in the shipped tum-bindings.conf",
        ],
        see_also=["tum-push", "tum-flip"],
    ),
    dict(
        name="import",
        purpose="adopt the current pane as a utility (anonymous or named)",
        synopsis=[
            "**tum import** [*name*]",
            "**tum import** **-h** | **--help**",
        ],
        desc=[
            "Adopt the current tmux pane as a managed utility. With no name, the "
            "import is **anonymous**: the pane is tagged `src=imported-anon`, given "
            "an auto-generated utility name, and becomes borrowable, hideable, and "
            "closeable like any utility. No file is written; close it and it is "
            "gone, and it cannot survive a server restart.",

            "With a *name*, the import is **named**: command, arguments, working "
            "directory, and environment are captured at maximum fidelity from "
            "`/proc/$pid/` and written to a `<name>.util` definition file "
            "(`src=imported-named`). Thereafter it is a normal, editable utility, "
            "available in any session. The captured file is meant to be hand-edited "
            "to refine.",

            "Named import needs Linux for `/proc/$pid/` capture; anonymous import "
            "and every other command work anywhere tmux does. PID is read "
            "ephemerally at import time only \u2014 it is never stored as a binding key.",
        ],
        examples=[
            "tum import               # anonymous: temporary, not saved",
            "tum import prod-db       # named: captures cmd/args/cwd/env to prod-db.util",
        ],
        see_also=["tum-borrow", "tum-defs"],
    ),
    dict(
        name="ls",
        purpose="list every utility pane across all sessions",
        synopsis=[
            "**tum ls**",
            "**tum ls** **-h** | **--help**",
        ],
        desc=[
            "List every managed utility pane across all sessions, queried from "
            "`tmux list-panes -a`. The global view: any session can borrow from "
            "the shared pool, so this is where you see where every instance lives "
            "and what it is bound to.",

            "Columns: Utility, Layout, Host (a session:pane id, or `hidden`, "
            "`host gone`, or `pushed`), Home (the owning pane, or `pool`), Slot, "
            "Geometry, and State (`shown`, `hidden`, `pushed`, or `orphan`).",
        ],
        examples=[
            "tum ls                   # every utility pane, everywhere",
            "# bound to  t g l  in the shipped tum-bindings.conf",
        ],
        see_also=["tum-check", "tum-status"],
    ),
    dict(
        name="check",
        purpose="list orphans (host dead, utility alive)",
        synopsis=[
            "**tum check**",
            "**tum check** **-h** | **--help**",
        ],
        desc=[
            "List orphans \u2014 managed panes whose `host` points at a pane id that is "
            "no longer in `list-panes -a` (the host pane died but the utility pane "
            "is still alive). Orphans are marked `!` and left in place; there is no "
            "auto-action and no proactive hook on pane death.",

            "Detection is lazy: it happens when you run `tum check` (or `tum ls`), "
            "not when the host dies. To clear an orphan, re-borrow it (which "
            "re-binds it to the current host) or close it. A fully-dead pane \u2014 "
            "utility gone too \u2014 needs no handling: its state died with it.",
        ],
        examples=[
            "tum check                # list orphans: host dead, utility alive",
            "# bound to  t g c  in the shipped tum-bindings.conf",
        ],
        see_also=["tum-ls", "tum-borrow", "tum-close"],
    ),
    dict(
        name="status",
        purpose="emit status-bar / prompt glyphs for a pane",
        synopsis=[
            "**tum status** [*pane_id*]",
            "**tum prompt**",
            "**tum status** **-h** | **--help**",
        ],
        desc=[
            "**tum status** emits the glyph string for a pane, for use in the tmux "
            "status bar (tmux interpolates `#{pane_id}` into `#(tum status "
            "#{pane_id})`). A host pane with borrowed things attached shows the "
            "host glyph (default `\u00f7`, configurable via `@tum-host-glyph`); a "
            "borrowed pane shows the borrowed glyph (default `\u00a7`, via "
            "`@tum-borrowed-glyph`) plus the utility name; an orphan shows a `!` "
            "prefix.",

            "**tum prompt** emits the same glyphs as a snippet for the shell "
            "prompt (PS1). Source it from your `.bashrc` (a small snippet ships for "
            "that); optional one-block snippets for starship and powerlevel10k are "
            "documented but never auto-patched into your prompt config.",

            "Both glyphs are configurable through the `@tum-*` static options; see "
            "**tum-defs**(5).",
        ],
        examples=[
            "# in tmux.conf:  set -g status-right '#(tum status #{pane_id})'",
            "tum prompt               # PS1 snippet for the shell prompt",
            "# bound to  t g s  in the shipped tum-bindings.conf",
        ],
        see_also=["tum-ls", "tum-check", "tum-defs"],
    ),
    dict(
        name="popup",
        purpose="open the interactive menu over every command",
        synopsis=[
            "**tum popup**",
            "**tum popup** **-h** | **--help**",
        ],
        desc=[
            "Open a `display-popup` menu that exposes every `tum` command through "
            "arrows and enter. It is the catch-all for anything without a dedicated "
            "key binding: the popup delegates to the same CLI commands every "
            "binding uses, so anything doable in the popup is scriptable and a CLI "
            "fix fixes the UI too.",

            "Requires tmux \u2265 3.2 (the binding constraint is `display-popup`). If "
            "the popup is not implemented, the chooser and the cheatsheet still "
            "cover discovery.",
        ],
        examples=[
            "tum popup                # full interactive menu of every command",
            "# bound to  t u  in the shipped tum-bindings.conf",
        ],
        see_also=["tum-cheatsheet", "tum-keymap"],
    ),
    dict(
        name="cheatsheet",
        purpose="open a popup listing every key binding",
        synopsis=[
            "**tum cheatsheet**",
            "**tum cheatsheet** **-h** | **--help**",
        ],
        desc=[
            "Open a `display-popup` listing every key binding in the shipped "
            "`tum-bindings.conf`, grouped, so you never have to leave tmux to "
            "remember a shortcut. The full binding scheme is documented in "
            "**tum-keymap**(5).",

            "Requires tmux \u2265 3.2 (`display-popup`).",
        ],
        examples=[
            "tum cheatsheet           # popup of every key binding, grouped",
            "# bound to  t ?  in the shipped tum-bindings.conf",
        ],
        see_also=["tum-popup", "tum-keymap"],
    ),
]


def fmt_see_also(names):
    parts = []
    for n in names:
        sec = "5" if n in ("tum-defs", "tum-keymap") else "1"
        parts.append("**%s**(%s)" % (n, sec))
    parts.append("**tmux**(1)")
    return ", ".join(parts)


def render(cmd):
    name = cmd["name"]
    title = "tum-" + name
    out = []
    out.append("---")
    out.append("title: %s" % title)
    out.append("section: 1")
    out.append("header: %s" % HEADER)
    out.append("---")
    out.append("")
    out.append("## NAME")
    out.append("")
    out.append("**tum-%s** \u2014 %s" % (name, cmd["purpose"]))
    out.append("")
    out.append("## SYNOPSIS")
    out.append("")
    for s in cmd["synopsis"]:
        out.append(s)
        out.append("")
    out.append("## DESCRIPTION")
    out.append("")
    for p in cmd["desc"]:
        out.append(p)
        out.append("")
    out.append("## OPTIONS")
    out.append("")
    out.append("- **-h**, **--help**")
    out.append("    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of "
               "this page) and exit. For bare **tum**, list every subcommand.")
    out.append("")
    out.append("## EXAMPLES")
    out.append("")
    out.append("```")
    for e in cmd["examples"]:
        out.append(e)
    out.append("```")
    out.append("")
    out.append("## SEE ALSO")
    out.append("")
    out.append(fmt_see_also(cmd["see_also"]))
    out.append("")
    return "\n".join(out)


def main():
    os.makedirs(MAN_DIR, exist_ok=True)
    for cmd in COMMANDS:
        path = os.path.join(MAN_DIR, "tum-%s.1.md" % cmd["name"])
        with open(path, "w") as f:
            f.write(render(cmd))
        print("wrote", path)
    print("done: %d command manpages" % len(COMMANDS))


if __name__ == "__main__":
    main()
