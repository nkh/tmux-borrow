---
title: tum-ls
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-ls** — list every utility pane across all sessions

## SYNOPSIS

**tum ls**

**tum ls** **-h** | **--help**

## DESCRIPTION

List every managed utility pane across all sessions, queried from `tmux list-panes -a`. The global view: any session can borrow from the shared pool, so this is where you see where every instance lives and what it is bound to.

Columns: Utility, Layout, Host (a session:pane id, or `hidden`, `host gone`, or `pushed`), Home (the owning pane, or `pool`), Slot, Geometry, and State (`shown`, `hidden`, `pushed`, or `orphan`).

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum ls                   # every utility pane, everywhere
# bound to  t g l  in the shipped tum-bindings.conf
```

## SEE ALSO

**tum-check**(1), **tum-status**(1), **tmux**(1)
