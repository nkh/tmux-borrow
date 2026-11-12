---
title: tum-cheatsheet
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-cheatsheet** — open a popup listing every key binding

## SYNOPSIS

**tum cheatsheet**

**tum cheatsheet** **-h** | **--help**

## DESCRIPTION

Open a `display-popup` listing every key binding in the shipped `tum-bindings.conf`, grouped, so you never have to leave tmux to remember a shortcut. The full binding scheme is documented in **tum-keymap**(5).

Requires tmux ≥ 3.2 (`display-popup`).

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum cheatsheet           # popup of every key binding, grouped
# bound to  t ?  in the shipped tum-bindings.conf
```

## SEE ALSO

**tum-popup**(1), **tum-keymap**(5), **tmux**(1)
