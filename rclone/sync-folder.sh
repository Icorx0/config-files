#!/usr/bin/env bash
# Mirror a local folder to an rclone remote.
#   Usage: sync-folder.sh SRC DST
# Run by the rclone-sync-*.timer systemd user units, or manually.
set -euo pipefail

SRC="${1:?usage: sync-folder.sh SRC DST}"
DST="${2:?usage: sync-folder.sh SRC DST}"

# Prefer rclone on PATH (e.g. apt-installed /usr/bin/rclone), otherwise fall
# back to the user-local install used when set up without root.
RCLONE="${RCLONE:-$(command -v rclone || echo "$HOME/.local/bin/rclone")}"

[ -x "$RCLONE" ] || { echo "rclone not found at $RCLONE" >&2; exit 1; }
[ -d "$SRC" ]   || { echo "source folder missing: $SRC" >&2; exit 1; }

# --checksum compares by content hash, so files re-seeded/moved with a new
# modtime are not needlessly re-uploaded.
exec "$RCLONE" sync "$SRC" "$DST" \
  --checksum \
  --exclude '.git/**' \
  --exclude '.gitignore' \
  --log-level INFO
