---
title: tum-push
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-push** — detach a borrowed pane onto the LIFO stack

## SYNOPSIS

**tum push**

**tum push** **-h** | **--help**

## DESCRIPTION

Detach the focused borrowed pane onto a LIFO stack. The pane parks in the hidden session with no host; its geometry is recorded and a push sequence number is stamped on its state. Push is how you hand a utility to another session: push here, **tum pop** there.

Push is context-aware like **tum flip** and **tum close**: from a focused borrowed pane it pushes that pane; from a host with one borrowed thing it pushes that; from a host with several it opens the chooser.

Push is independent of the pool/owned distinction — `home` is untouched, and a pushed pane attaches to whoever pops it. A pushed pane has no host and is **not** reachable by **tum flip**; bring it back only with **tum pop**. Non-contiguous sequence numbers are fine, since panes may be closed between pushes.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum push                 # focused borrowed pane (or host's single) onto the stack
# bound to  t p  in the shipped tum-bindings.conf
# then in another session:  tum pop
```

## SEE ALSO

**tum-pop**(1), **tum-flip**(1), **tum-close**(1), **tmux**(1)
