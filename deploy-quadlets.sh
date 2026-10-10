#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="./quadlets"
DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/containers/systemd"

if [[ ! -d "$SRC_DIR" ]]; then
    echo "Error: source directory '$SRC_DIR' not found (run from the repo root)." >&2
    exit 1
fi

mkdir -p "$DEST_DIR"

echo "Copying $SRC_DIR -> $DEST_DIR"
cp -rv "$SRC_DIR"/. "$DEST_DIR"/

QUADLET=""
for candidate in /usr/libexec/podman/quadlet /usr/lib/podman/quadlet; do
    if [[ -x "$candidate" ]]; then
        QUADLET="$candidate"
        break
    fi
done

if [[ -z "$QUADLET" ]]; then
    echo "Error: quadlet binary not found (is podman installed?)." >&2
    exit 1
fi

echo
echo "==> Quadlet dry run (check the generated ExecStart)"
"$QUADLET" -dryrun -user

# Fallback for sessions without pam_systemd (e.g. su/sudo -u); requires lingering
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

shopt -s nullglob

echo
echo "==> Pulling images"
grep -h '^Image=' "$DEST_DIR"/*.container | cut -d= -f2- | sort -u | while read -r image; do
    podman pull "$image"
done

echo
echo "==> Reloading systemd user daemon"
systemctl --user daemon-reload

# Restart pods via their -pod.service (restarts their containers too);
# containers that belong to a pod are skipped, standalone ones restarted directly.
UNITS=()
for f in "$DEST_DIR"/*.pod; do
    UNITS+=("$(basename "$f" .pod)-pod.service")
done
for f in "$DEST_DIR"/*.container; do
    grep -q '^Pod=' "$f" && continue
    UNITS+=("$(basename "$f" .container).service")
done

echo "==> Restarting: ${UNITS[*]}"
systemctl --user restart "${UNITS[@]}"

systemctl --user --no-pager status "${UNITS[@]}" || true
