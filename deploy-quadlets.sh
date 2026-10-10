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

echo
echo "==> Reloading systemd user daemon"
systemctl --user daemon-reload

echo "==> (Re)starting caddy"
systemctl --user restart caddy jonasluethiweb

systemctl --user --no-pager status caddy || true
