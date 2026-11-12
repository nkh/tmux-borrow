---
title: tum-flip
section: 1
header: tmux-borrow Manual
---

## NAME

**tum-flip** — hide or show a borrowed thing by slot, or context-aware

## SYNOPSIS

**tum flip** [*slot*]

**tum flip** **-h** | **--help**

## DESCRIPTION

Toggle a borrowed thing between shown and hidden. With a *slot* (a single character in `0–9` or `a–z`), toggle the thing bound to that slot in the current host window. Hide parks the pane in the hidden session (clears `host`, captures geometry); show brings it back beside its host and restores the recorded geometry.

With no slot, **tum flip** is context-aware: from a focused borrowed pane it toggles just that pane; from a host with one borrowed thing it toggles that; from a host with several it opens the chooser. An owned utility flipped back from hidden returns only to its home pane; a flip from another pane does nothing to it.

A layout's slot toggles **all** its members as a group: a group hide hides every member (including any individually shown); a group show shows every member (including any individually hidden). A member's own slot toggles just that member, which a later group show brings back. The process is never restarted — only moved.

## OPTIONS

- **-h**, **--help**
    Print a short synopsis (the SYNOPSIS and EXAMPLES sections of this page) and exit. For bare **tum**, list every subcommand.

## EXAMPLES

```
tum flip 1               # hide or show the thing in slot 1
tum flip                 # context-aware: focused pane, or host's single, or chooser
tum flip d               # toggle the whole 'dev' layout group
```

## SEE ALSO

**tum-close**(1), **tum-push**(1), **tum-keymap**(5), **tmux**(1)
