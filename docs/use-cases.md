# tmux-borrow — functional use cases

These scenarios test whether the requirements hold together. Each is a concrete workflow mapped to the requirements it exercises, not an example meant to sell the application. The persuasive examples (file manager per window, shared monitor, etc.) live in the user guide.

## How to read a scenario

Each scenario lists the **setup** (what exists beforehand), the **action** (what the user does), the **expected result** (what tmux-borrow does and what state looks like), and the **requirements exercised** (the requirement sections that must hold for this to work). A scenario is a test: if any requirement it lists is not met, the scenario fails.

---

## 1. Borrow a layout, close one member, recreate it

**Setup.** A layout `dev` with members `editor`, `term`, `logs`. The host pane is an ordinary shell in `work:0`.

**Action.**
1. `tum borrow dev` — the three members attach beside the host at their declared positions, each with its own slot; the layout group gets a slot too.
2. Focus the `logs` pane. Press the close key.
3. `tum borrow --new logs` (or `tum borrow logs` if no other `logs` instance is hidden).

**Expected result.** After step 2, `logs` is gone; `editor` and `term` continue, their `@tum-layout` unchanged. After step 3, a fresh `logs` instance attaches; it carries the same `@tum-layout` id, so it is part of the same group for group flip-flop.

**Requirements.** Layouts; Close (context-aware); Borrowing (modes); State representation (`@tum-layout`).

## 2. Two borrowed utilities on one host, hide one from the host pane

**Setup.** Host pane in `work:0`. Two utilities `htop` (slot `1`) and `lazygit` (slot `2`) are borrowed, both shown.

**Action.** From the host pane (not from either borrowed pane), press `<prefix> H 1`.

**Expected result.** `htop` hides (parks in the hidden session, `@tum-host` cleared); `lazygit` stays shown. Pressing `<prefix> H 1` again shows `htop` at its last geometry.

**Requirements.** Flip-flop (slot keys, toggle by slot); Hide (clears host binding, keeps geometry).

## 3. Push a utility from one session, pop it in another

**Setup.** Session `a` has `htop` borrowed beside a host pane. Session `b` has an ordinary shell.

**Action.**
1. In session `a`, focus the `htop` pane. `tum push`.
2. Switch to session `b`. `tum pop`.

**Expected result.** After step 1, `htop` is detached from its host, has no `@tum-host`, carries `@tum-pushed` and a `@tum-push-seq`, and its geometry is recorded. After step 2, `htop` attaches beside the session `b` host at its recorded geometry; `@tum-pushed` is cleared and `@tum-host` is set to the session `b` pane.

**Requirements.** Push and pop; State representation (`@tum-pushed`, `@tum-push-seq`, `@tum-geometry`).

## 4. Borrow existing vs borrow new

**Setup.** Two `ranger` instances are hidden in the pool. Neither is bound to the current host.

**Action.**
1. `tum borrow ranger` — the chooser opens (two instances match); pick one.
2. `tum borrow --new ranger` — a third instance is created and borrowed.
3. `tum borrow --existing ranger` — the chooser opens over the two remaining hidden instances; if none were hidden, it errors.

**Expected result.** Each mode behaves as specified. The host binding is set on the borrowed pane in all three cases.

**Requirements.** Borrowing (modes, resolution order); Host binding.

## 5. Flip-flop a layout (hide all, show all)

**Setup.** Layout `dev` (editor, term, logs) is borrowed beside the host, all members shown. The layout group has slot `d`.

**Action.** From the host pane, press `<prefix> H d`. Then press it again.

**Expected result.** First press hides all three members together (they park in the hidden session, `@tum-host` cleared, `@tum-layout` kept). Second press shows all three at their last geometries.

**Requirements.** Flip-flop (layout slot toggles all members); Hide and show; Geometry restore.

## 6. Flip-flop a single layout member

**Setup.** Layout `dev` is borrowed, all members shown. `term` has slot `t`.

**Action.** From the host pane, press `<prefix> H t`.

**Expected result.** Only `term` hides; `editor` and `logs` stay shown. `term` keeps its `@tum-layout`. Pressing `<prefix> H d` (the layout slot) still toggles the group — and `term` shows again with the others.

**Requirements.** Flip-flop (member slot); Hide (keeps `@tum-layout`); Layouts (member remains part of group).

## 7. Import a pane anonymously, borrow it elsewhere

**Setup.** Session `a` has an ordinary pane running `bpftrace` (not a defined utility). Session `b` has a host pane.

**Action.**
1. In session `a`, focus the `bpftrace` pane. `tum import`.
2. Switch to session `b`. `tum borrow` (no name) — the chooser lists the anonymous import; pick it.

**Expected result.** After step 1, the pane is tagged `@tum-source=imported-anon`, gets an auto-generated utility name, and can be hidden, shown, pushed, and closed like any utility. No file is written. After step 2, it attaches beside the session `b` host. Closing it removes it completely; it cannot be re-borrowed.

**Requirements.** Import (anonymous); Borrowing (no-name mode); State representation (`@tum-source`).

## 8. Import a pane by name, re-borrow in a new session

**Setup.** A pane running `psql -h prod-db` in session `a`. No `psql` utility is defined.

**Action.**
1. Focus the `psql` pane. `tum import prod-db`.
2. End the tmux server; start a new one. The definition file `prod-db.util` now exists.
3. In session `b`, `tum borrow prod-db`.

**Expected result.** Step 1 captures command (`psql`), args (`-h prod-db`), cwd, and env from `/proc/$pid/`, writes `~/.config/tum/prod-db.util`. Step 3 creates a fresh instance from the saved definition and borrows it.

**Requirements.** Import (named, max fidelity, editable file); Definitions (utility file keys); Borrowing (creates if not running).

## 9. Close from the borrowed pane vs close from the host

**Setup.** `htop` is borrowed beside a host pane. Both panes exist.

**Action.**
1. Focus the `htop` pane. Press the close key.
2. Re-borrow `htop`. Focus the host pane. Press the close key.

**Expected result.** In step 1, `htop` is closed (kill-pane, state gone). In step 2, with one borrowed thing on the host, the host-side close kills `htop`. No confirmation in either case. No cleanup needed.

**Requirements.** Close (context-aware); Core model (kill-pane kills state).

## 10. Host pane dies — orphan detection and recovery

**Setup.** `htop` is borrowed beside host pane `%5` in `work:0`. The user kills `%5` with tmux's own `kill-pane`.

**Action.**
1. `tum ls` — `htop` shows state `orphan`, host `host gone`.
2. `tum borrow htop` — the default mode finds the orphaned instance (it is hidden, `@tum-host` points at dead `%5`), re-binds it to the current host.

**Expected result.** The orphan is detected lazily (no hook fired on `%5`'s death). `@tum-host` is left intact and marked `!` until the user acts. Re-borrowing clears the dead binding and sets the new host.

**Requirements.** Orphan handling; Listings; Borrowing (resolution order).

## 11. Borrow by tag

**Setup.** Utilities `htop`, `nload`, `iftop` are all tagged `monitor`. Several instances of each may be hidden.

**Action.** `tum borrow --tag monitor`.

**Expected result.** The chooser lists all hidden instances tagged `monitor`. Picking one borrows it. If none are hidden, the chooser lists the definitions (uninstantiated) and picking one creates and borrows.

**Requirements.** Borrowing (by tag, no-name); Definitions (tags); State representation (`@tum-tags`).

## 12. Borrow with no name (chooser over all)

**Setup.** Several utilities and layouts are defined; some have hidden instances, some do not.

**Action.** `tum borrow` (no arguments).

**Expected result.** The chooser lists every utility and layout, instantiated or not, with state shown. Picking an instantiated one borrows that instance. Picking an uninstantiated one creates and borrows. Picking a layout borrows the layout (all members).

**Requirements.** Borrowing (no-name mode); Chooser; Layouts.

## 13. Close a layout member — remaining members continue

**Setup.** Layout `dev` (editor, term, logs) is borrowed, all shown.

**Action.** Focus `term`. Press the close key.

**Expected result.** `term` is gone. `editor` and `logs` continue with their `@tum-layout` unchanged. There is no "layout instance" to repair — the layout is just an id on the surviving panes. Re-borrowing the `dev` layout definition would create a fresh group; the current group stays minus `term`.

**Requirements.** Close (in a layout); Layouts (no instance, id on panes); Core model.

## 14. Push two utilities, pop in reverse order

**Setup.** Session `a` has `htop` and `lazygit` both borrowed beside a host.

**Action.**
1. Focus `htop`. `tum push`.
2. Focus `lazygit`. `tum push`.
3. `tum pop` — `lazygit` attaches.
4. `tum pop` — `htop` attaches.

**Expected result.** LIFO order: `lazygit` (pushed last) pops first, `htop` pops second. Each pops at its recorded geometry. After both pops, the stack is empty.

**Requirements.** Push and pop (LIFO, geometry recorded); State representation (`@tum-push-seq`).

## 15. Slot key conflict — auto-assignment

**Setup.** Utility `htop` defines `slot: 1`. Utility `lazygit` also defines `slot: 1`. Both are borrowed to the same host.

**Action.** `tum borrow htop` then `tum borrow lazygit`.

**Expected result.** `htop` gets slot `1`. `lazygit`'s declared slot conflicts, so it is auto-assigned the next free slot (for example `2`). Both are flip-floppable by their actual slots. `tum ls` shows the assigned slots.

**Requirements.** Flip-flop (slot keys, auto-assigned on conflict); Definitions (slot key); Listings.
