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

echo
echo "==> Quadlet dry run (check the generated ExecStart)"
/usr/lib/podman/quadlet -dryrun -user

echo
echo "==> Reloading systemd user daemon"
systemctl --user daemon-reload

echo "==> Starting caddy"
systemctl --user restart caddy jonasluethiweb

systemctl --user --no-pager status caddy jonasluethiweb || true
