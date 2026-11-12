---
title: tum-close
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-close** — kill the focused borrowed pane (context-aware)

## SYNOPSIS

**tum close**

**tum close** **-h** | **--help**

## DESCRIPTION

Destroy the focused borrowed pane with `kill-pane`. The pane and all its state are gone; there is no cleanup and no confirmation — close is immediate, mirroring tmuxake.

Close is context-aware, sharing the target resolver with **tum flip** and **tum push**: if the focused pane is itself borrowed, close it; if the focused pane is a host with one borrowed thing, close that; if it is a host with several, open the chooser and close the selection.

Close works inside a layout: a closed member is gone from the group and the remaining members continue with their layout id unchanged. There is no layout instance to repair — the layout is just an id stamped on member panes. Close is destructive; to park a pane without destroying it, use **tum flip** instead.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum close                # focused borrowed pane, or host's single, or chooser-pick
# bound to  t x  in the shipped tum-bindings.conf (see tum-keymap(5))
```

## SEE ALSO

**tum-flip**(1), **tum-push**(1), **tum-keymap**(5), **tmux**(1)
