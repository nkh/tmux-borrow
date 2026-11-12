---
title: tum-check
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-check** — list orphans (host dead, utility alive)

## SYNOPSIS

**tum check**

**tum check** **-h** | **--help**

## DESCRIPTION

List orphans — managed panes whose `host` points at a pane id that is no longer in `list-panes -a` (the host pane died but the utility pane is still alive). Orphans are marked `!` and left in place; there is no auto-action and no proactive hook on pane death.

Detection is lazy: it happens when you run `tum check` (or `tum ls`), not when the host dies. To clear an orphan, re-borrow it (which re-binds it to the current host) or close it. A fully-dead pane — utility gone too — needs no handling: its state died with it.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum check                # list orphans: host dead, utility alive
# bound to  t g c  in the shipped tum-bindings.conf
```

## SEE ALSO

**tum-ls**(1), **tum-borrow**(1), **tum-close**(1), **tmux**(1)
