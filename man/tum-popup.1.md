---
title: tum-popup
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-popup** — open the interactive menu over every command

## SYNOPSIS

**tum popup**

**tum popup** **-h** | **--help**

## DESCRIPTION

Open a `display-popup` menu that exposes every `tum` command through arrows and enter. It is the catch-all for anything without a dedicated key binding: the popup delegates to the same CLI commands every binding uses, so anything doable in the popup is scriptable and a CLI fix fixes the UI too.

Requires tmux ≥ 3.2 (the binding constraint is `display-popup`). If the popup is not implemented, the chooser and the cheatsheet still cover discovery.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum popup                # full interactive menu of every command
# bound to  t u  in the shipped tum-bindings.conf
```

## SEE ALSO

**tum-cheatsheet**(1), **tum-keymap**(5), **tmux**(1)
