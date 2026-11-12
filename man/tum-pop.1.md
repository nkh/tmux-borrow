---
title: tum-pop
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-pop** — attach the top of the push stack to the current host

## SYNOPSIS

**tum pop**

**tum pop** **-h** | **--help**

## DESCRIPTION

Attach the highest-push pane from the stack to the current host pane, at the geometry recorded when it was pushed. The pane is consumed from the stack — its push field is cleared and its host is set to the current pane.

The stack is `list-panes -a` filtered to panes whose state carries a `push` field, sorted by push value descending, so **tum pop** is LIFO: the last thing pushed is the first thing popped. Push several utilities from anywhere, then pop them one by one to assemble a working set — no layout file needed.

Pop is independent of pool/owned: `home` is untouched. If the stack is empty, pop does nothing.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum pop                  # attach the most-recently-pushed pane here, at its geometry
# bound to  t P  in the shipped tum-bindings.conf
```

## SEE ALSO

**tum-push**(1), **tum-flip**(1), **tmux**(1)
