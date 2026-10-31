# 20 use cases

These scenarios are intended to test whether the requirements solve real workflows for power users, terminal enthusiasts, advanced Linux users, and programmers.

1. **Project file manager per window** — Each project window gets its own `lf` or `ranger` instance rooted in that project's directory. The instance is window-scoped and can be borrowed into a split in that same working context.
2. **Shared system monitor** — One `htop` instance lives in a background tools session and can be borrowed into any project window.
3. **Multiple log streams** — Several `tail -F` instances from different services are borrowed together into one debugging window.
4. **Ad hoc build log** — Launch `tail -F ./build.log` without registering it, assign it to an automatically selected home session, and borrow it later.
5. **Registered REPL with arguments** — A registered `ipython`, `irb`, or language REPL accepts project-specific startup arguments at launch.
6. **Database console on demand** — A registered `psql` utility accepts a connection profile or database name; a split borrow prompts for the target when omitted.
7. **Profiler attached to a process** — Launch a profiler as an ad hoc instance, pass a PID when borrowing into a split, and return it when profiling ends.
8. **Git UI across projects** — A shared `lazygit` instance can be borrowed into a window, while a project-scoped instance remains tied to a particular working directory.
9. **Debugger and application logs** — Borrow a debugger pane and two log panes from separate home sessions into one temporary debugging layout.
10. **Serial console** — Keep a long-running serial terminal in a dedicated home session and borrow it into the active hardware project.
11. **Network inspection** — Keep `nload`, `iftop`, or a packet summary process running in a tools session; borrow it temporarily without restarting capture.
12. **Remote shell pool** — Maintain several named SSH sessions in home sessions; select one from a tree and borrow the existing connection.
13. **Compiler/test feedback** — Keep a watcher or test runner running in the background, then borrow its pane into whichever project window needs attention.
14. **Temporary incident room** — Assemble several borrowed utilities from different sessions, save the borrowed-only layout, and later restore it without touching ordinary editor/shell panes.
15. **Switch task context** — Replace one set of borrowed panes with another saved layout while preserving the current working window's ordinary panes.
16. **Kill stale background tools** — Use the tree selector to find and terminate a utility in a home session without manually switching sessions.
17. **Duplicate session names** — Run two projects with identical visible home-session names/geometry labels; the manager differentiates them using stable internal IDs.
18. **Window-specific profiler/file browser** — Create one instance per user window, each with its own target path or process, while allowing shared utilities to be reused globally.
19. **Custom utility color coding** — Give borrowed database, log, and monitoring panes distinct background colors; restore original colors when returned.
20. **Recover after a tmux interruption** — On next invocation, reconcile manager metadata with live tmux sessions/panes, report missing resources, and offer recovery rather than silently discarding state.

## Acceptance scenarios

The first usable release should demonstrate at least these end-to-end flows:

- Register and launch a utility with arguments.
- Launch an ad hoc utility with CLI overrides and inherited defaults.
- Assign ad hoc utility to an explicit and an automatic home session.
- Borrow a running utility pane into a split with an interactive argument prompt.
- Borrow several utilities from different sessions into one working window.
- Borrow an ordinary pane from a non-home session.
- Return one borrowed pane and return all borrowed panes.
- Save/apply a borrowed-only layout without capturing or destroying ordinary panes.
- Terminate a utility from its borrowed location and from its home-session listing.
- Open/edit config and layouts without knowing their filesystem paths.
