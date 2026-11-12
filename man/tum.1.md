---
title: tum
section: 1
header: tmux-borrow Manual
---

## NAME

tum — borrow, reuse, and flip-flop utility panes inside tmux

## SYNOPSIS

**tum** *command* \[*args*...]

**tum** **-h** | **--help**

**tum** *command* **-h** | **--help**

## DESCRIPTION

**tum** manages "borrowed" utility panes (htop, a log tail, an editor, a DB
console, …) beside your host pane in tmux. A utility is defined once in a
`.util` file; `tum borrow` attaches an instance beside the current pane, and
`tum flip` hides/shows it without losing its process. Instances are reused:
hidden ones return to the same host, pool ones can be borrowed by any host, and
`tum new` makes an instance owned by one host.

## COMMANDS

- **tum borrow** \[*util*|*layout*\]
    Attach a utility (or layout) beside the host; reuse a hidden instance if one
    exists for this host, else the pool, else create. With no argument, open the
    chooser.
- **tum new** *util*
    Create an instance owned by the current host (flip returns it only here).
- **tum flip** \[*slot*\]
    Hide/show the slot's bound thing. No slot → context-aware (focused borrowed
    pane, else the host's single thing, else chooser).
- **tum close**
    Kill the focused borrowed pane (or chooser-pick). No confirmation.
- **tum push** / **tum pop**
    Detach the focused borrowed pane onto a LIFO stack / reattach the top.
- **tum import** \[*name*\]
    Make the current pane a temporary utility (anonymous), or capture it to a
    named `.util` file.
- **tum ls**
    List every utility pane across sessions with its state.
- **tum check**
    List orphans (utility whose host pane is dead).
- **tum status** / **tum prompt**
    Emit status-bar / PS1 glyphs for host, borrowed, and orphan panes.
- **tum popup** / **tum cheatsheet**
    Open a `display-popup` menu of all commands / a list of key bindings.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (extracted from this manpage's source) for the given
    command, or the command index for bare **tum**.

## EXAMPLES

```
tum borrow htop          # attach htop beside this pane (reuse or create)
tum new editor           # an editor owned by this host
tum flip                 # hide/show the focused borrowed thing
tum ls                   # see every utility pane and its state
```

## FILES

- *~/.config/tum/*.util*
    Utility and layout definitions. See **tum-defs**(5).

## SEE ALSO

**tmux**(1), **tum-defs**(5), **tum-keymap**(5), and the per-command pages
**tum-borrow**(1), **tum-new**(1), **tum-flip**(1), **tum-close**(1),
**tum-push**(1), **tum-pop**(1), **tum-import**(1), **tum-ls**(1),
**tum-check**(1), **tum-status**(1), **tum-popup**(1), **tum-cheatsheet**(1).
