# Layouts

`tum layout save NAME` records only manager-owned utility panes in the current arrangement. It excludes ordinary user panes. For arguments, choose omit (default), a named preset reference, or explicitly approved non-secret values.

`tum layout restore NAME` adds utility panes incrementally to the current window or creates dedicated windows. It must not replace or wholesale rearrange ordinary panes. All missing required values are collected before restore starts.

`tum layout clone SOURCE DEST` creates a new recipe. Shared items retain shared policy; per-window items resolve/create destination instances. Cloning never moves source resources or copies secrets.
