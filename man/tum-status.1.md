---
title: tum-status
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-status** — emit status-bar / prompt glyphs for a pane

## SYNOPSIS

**tum status** [*pane_id*]

**tum prompt**

**tum status** **-h** | **--help**

## DESCRIPTION

**tum status** emits the glyph string for a pane, for use in the tmux status bar (tmux interpolates `#{pane_id}` into `#(tum status #{pane_id})`). A host pane with borrowed things attached shows the host glyph (default `÷`, configurable via `@tum-host-glyph`); a borrowed pane shows the borrowed glyph (default `§`, via `@tum-borrowed-glyph`) plus the utility name; an orphan shows a `!` prefix.

**tum prompt** emits the same glyphs as a snippet for the shell prompt (PS1). Source it from your `.bashrc` (a small snippet ships for that); optional one-block snippets for starship and powerlevel10k are documented but never auto-patched into your prompt config.

Both glyphs are configurable through the `@tum-*` static options; see **tum-defs**(5).

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
# in tmux.conf:  set -g status-right '#(tum status #{pane_id})'
tum prompt               # PS1 snippet for the shell prompt
# bound to  t g s  in the shipped tum-bindings.conf
```

## SEE ALSO

**tum-ls**(1), **tum-check**(1), **tum-defs**(5), **tmux**(1)
