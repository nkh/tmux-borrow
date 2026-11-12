---
title: tum-import
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-import** — adopt the current pane as a utility (anonymous or named)

## SYNOPSIS

**tum import** [*name*]

**tum import** **-h** | **--help**

## DESCRIPTION

Adopt the current tmux pane as a managed utility. With no name, the import is **anonymous**: the pane is tagged `src=imported-anon`, given an auto-generated utility name, and becomes borrowable, hideable, and closeable like any utility. No file is written; close it and it is gone, and it cannot survive a server restart.

With a *name*, the import is **named**: command, arguments, working directory, and environment are captured at maximum fidelity from `/proc/$pid/` and written to a `<name>.util` definition file (`src=imported-named`). Thereafter it is a normal, editable utility, available in any session. The captured file is meant to be hand-edited to refine.

Named import needs Linux for `/proc/$pid/` capture; anonymous import and every other command work anywhere tmux does. PID is read ephemerally at import time only — it is never stored as a binding key.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum import               # anonymous: temporary, not saved
tum import prod-db       # named: captures cmd/args/cwd/env to prod-db.util
```

## SEE ALSO

**tum-borrow**(1), **tum-defs**(5), **tmux**(1)
