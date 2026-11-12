#!/usr/bin/env bash
# scripts/install-tmux.sh — install tmux locally WITHOUT root, by extracting the
# precompiled binary from its Debian .deb (and the one runtime .so it needs that
# this minimal image lacks). Used in the tmux-borrow sandbox to run `make
# viability` / `make test` against a real tmux server.
#
# Why: the container has apt-get but no root (dpkg lock) and no dev headers, so
# neither `apt-get install` nor a from-source build is available. `apt-get
# download` fetches .debs without the lock, and dpkg-deb -x extracts them
# without installing — so we can stage the binary + its missing lib into a
# writable prefix (/usr/local) and wrap it with LD_LIBRARY_PATH.
#
# Result: tmux 3.5a at /usr/local/bin/tmux (a thin wrapper around
# /usr/local/bin/tmux.real that points at the staged libevent .so). Verify with
# `tmux -V`.
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
WORK="${TMPDIR:-/tmp}/tmux-install"
mkdir -p "$WORK"

echo "==> fetching tmux + libevent-core .debs (no root needed)"
cd "$WORK"
apt-get download tmux libevent-core-2.1-7t64 2>/dev/null || apt-get download tmux libevent-core-2.1-7

TMUX_DEB=$(ls tmux_*.deb | head -1)
LIBEV_DEB=$(ls libevent-core-*.deb | head -1)

echo "==> extracting"
rm -rf pkg lib
mkdir -p pkg lib
dpkg-deb -x "$TMUX_DEB" pkg
dpkg-deb -x "$LIBEV_DEB" lib

TMUX_BIN_PKG="pkg/usr/bin/tmux"
LIBSO=$(find lib -name 'libevent_core-2.1.so.7' -printf '%h\n' | head -1)

if [[ ! -x "$TMUX_BIN_PKG" || -z "$LIBSO" ]]; then
  echo "install-tmux: could not find tmux binary or libevent .so after extract" >&2
  exit 1
fi

echo "==> staging binary + lib to $PREFIX"
install -d "$PREFIX/bin"
install -m 0755 "$TMUX_BIN_PKG" "$PREFIX/bin/tmux.real"

# absolute path to the staged lib, for the wrapper
ABSLIB="$(cd "$LIBSO" && pwd)"

cat > "$PREFIX/bin/tmux" <<EOF
#!/usr/bin/env bash
export LD_LIBRARY_PATH="${ABSLIB}:\${LD_LIBRARY_PATH}"
exec "$PREFIX/bin/tmux.real" "\$@"
EOF
chmod +x "$PREFIX/bin/tmux"

echo "==> verifying"
hash -r 2>/dev/null || true
"$PREFIX/bin/tmux" -V

# smoke test on a throwaway socket
"$PREFIX/bin/tmux" -L install-smoke -f /dev/null new-session -d -s s >/dev/null 2>&1
"$PREFIX/bin/tmux" -L install-smoke list-sessions >/dev/null 2>&1 && echo "smoke: server starts and lists" || true
"$PREFIX/bin/tmux" -L install-smoke kill-server 2>/dev/null || true

echo "==> done: tmux at $PREFIX/bin/tmux"
