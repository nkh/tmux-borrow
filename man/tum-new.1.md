---
title: tum-new
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-new** — create a fresh owned instance and borrow it

## SYNOPSIS

**tum new** [*util*|*layout*]

**tum new** **-h** | **--help**

## DESCRIPTION

Always create a fresh instance owned by the current host pane (its `home` is set to this pane), then borrow it. It is a sibling of **tum borrow** that skips the reuse-hidden branch: where `borrow` reuses first, `new` always creates.

An owned instance flip-flops back only to its home pane after a hide; another host cannot take it by name. To move an owned instance elsewhere, that host must pick it explicitly from the no-name chooser, which re-homes it. This is the project-file-manager case: a `ranger` that belongs to one window.

With no argument, the chooser opens over all utilities and layouts; every pick creates a fresh owned instance, whether or not one already exists. On a layout, every member is created fresh and owned.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum new ranger           # an owned ranger for this window
tum new                  # chooser over all; every pick creates a fresh owned instance
tum new debug            # create a fresh owned 'debug' layout group
```

## SEE ALSO

**tum-borrow**(1), **tum-flip**(1), **tum-defs**(5), **tmux**(1)
