# Troubleshooting

**Instance is unknown:** the manager cannot prove the recorded pane exists or still belongs to the instance. Run `tum doctor`; do not kill a pane based on a similar command line.

**Host pane moved:** the association may be orphaned after external tmux movement. Use the repair action; the utility remains running.

**Home session deleted:** the manager may recreate it from metadata. It will not substitute another same-named session.

**fzf unavailable:** use numbered selection or `--instance ID`. fzf is optional.

**Ordinary panes changed during restore:** this is a defect. Restore must add managed panes incrementally, never reset a mixed window's entire layout.
