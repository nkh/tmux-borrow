# Layouts

A layout is a named recipe for assembling manager-owned utility panes. It is not a snapshot of the entire tmux window. Ordinary user panes are not layout members and must remain untouched.

## Contents

A layout records utility references, instance policy, pane arrangement relationships among managed panes, destination mode (`current_window` or `separate_window`), optional size proportions, temporary appearance settings, and argument persistence policy. The first version needs a simple ordered split tree, not every possible tmux layout encoding.

## Restore

Resolve all definitions, instances, conflicts, and missing arguments before changing tmux. Add managed panes incrementally or create dedicated manager-owned windows. Do not apply a whole-window `select-layout` to a mixed window if that would resize ordinary panes. If a utility is already borrowed, report the conflict rather than silently stealing it.

## Clone

Cloning creates a new layout record and never moves source resources. `shared` items retain shared-instance policy; `per_window` items resolve/create an instance for the destination window; `new_instance` always creates one; `existing_instance` reuses only the explicitly identified instance if valid. Prompt for destination-specific arguments. Do not copy secrets.

## Saving arguments

Offer `omit` (default), `preset` (named preset reference), or `values` (explicitly approved non-secret values). Secret arguments cannot use `values`.
