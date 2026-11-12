#!/usr/bin/env bash
# scripts/build_docs_zip.sh — package the tmux-borrow documentation set into a
# downloadable zip. Builds from a clean staging directory so NO stray files
# (deleted docs, swap files, .git) can leak in. Only the intended files are
# copied, then zipped under a single top-level folder tmux-borrow-docs/.
set -euo pipefail

REPO="/home/z/my-project/tmux-borrow"
OUT="/home/z/my-project/download/tmux-borrow-docs.zip"
STAGE="/home/z/my-project/.zip-stage"
PKG="$STAGE/tmux-borrow-docs"

rm -f "$OUT"
rm -rf "$STAGE"
mkdir -p "$PKG/docs" "$PKG/man" "$PKG/scripts"

# 1. the updated README
cp "$REPO/README.md" "$PKG/"

# 2. the three docs/ files (spec, roadmap, design-rationale)
cp "$REPO"/docs/tmux-borrow-requirements.md "$PKG/docs/"
cp "$REPO"/docs/implementation-roadmap.md     "$PKG/docs/"
cp "$REPO"/docs/design-rationale.md           "$PKG/docs/"

# 3. every manpage source (.md, canonical) AND its rendered roff (.1/.5)
cp "$REPO"/man/*.md "$PKG/man/"
cp "$REPO"/man/*.1  "$PKG/man/" 2>/dev/null || true
cp "$REPO"/man/*.5  "$PKG/man/" 2>/dev/null || true

# 4. the manpage generator + the md2man fallback renderer
cp "$REPO"/scripts/gen_manpages.py "$PKG/scripts/"
cp "$REPO"/scripts/md2man.awk      "$PKG/scripts/"

# zip the staged tree (excludes any stray swap files defensively)
( cd "$STAGE" && zip -r "$OUT" tmux-borrow-docs -x '*.swp' '*.swo' )

rm -rf "$STAGE"

echo "wrote $OUT"
