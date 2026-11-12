---
title: tum-borrow
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-borrow** — attach a utility or layout beside the host pane

## SYNOPSIS

**tum borrow** [*util*|*layout*]

**tum borrow** **-h** | **--help**

## DESCRIPTION

Attach a utility (or layout) instance beside the current host pane, creating it first if none exists to reuse. Borrowing moves a pane with `join-pane`/`move-pane` — the process is moved, not restarted, so its state is preserved.

Default-mode resolution order: (1) an instance already bound to this host is re-shown; (2) else a hidden instance of this utility is borrowed (the chooser picks if several — pool instances are always available, owned instances only to their home host); (3) else a new **pool** instance is created and borrowed. An orphan whose host is dead counts as hidden here; re-borrowing clears the dead binding.

With no argument, the chooser opens over every utility and layout. Picking an instantiated one borrows that instance; picking an uninstantiated one creates and borrows it. Borrowing a layout borrows all its members into the host window at their declared positions.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum borrow htop          # reuse a hidden instance, else create a pool one
tum borrow               # chooser over all utilities and layouts
tum borrow dev           # borrow the 'dev' layout (all members attach)
```

## SEE ALSO

**tum-new**(1), **tum-flip**(1), **tum-close**(1), **tum-defs**(5), **tum-keymap**(5), **tmux**(1)
