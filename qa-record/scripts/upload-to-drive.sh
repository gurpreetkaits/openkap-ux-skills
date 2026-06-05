#!/usr/bin/env bash
# Upload a local video file to Google Drive via rclone and print a public shareable URL.
#
# Usage: upload-to-drive.sh <local-file> [remote-dir]
#   - local-file: path to the video to upload
#   - remote-dir: optional rclone destination (default: drive:QA-Recordings)
#
# Output:
#   - Progress is written to stderr.
#   - The final shareable URL is written to stdout (single line).

set -euo pipefail

FILE="${1:?Usage: $0 <local-file> [remote-dir]}"
REMOTE_DIR="${2:-${RCLONE_REMOTE:-qa-record:QA-Recordings}}"

if [ ! -f "$FILE" ]; then
  echo "ERROR: file not found: $FILE" >&2
  exit 1
fi

if ! command -v rclone >/dev/null 2>&1; then
  echo "ERROR: rclone is not installed. Run: brew install rclone" >&2
  exit 2
fi

REMOTE_NAME="${REMOTE_DIR%%:*}"
if ! rclone listremotes 2>/dev/null | grep -q "^${REMOTE_NAME}:$"; then
  echo "ERROR: rclone remote '${REMOTE_NAME}:' is not configured. Run: rclone config" >&2
  exit 3
fi

FILENAME="$(basename "$FILE")"
DEST="${REMOTE_DIR}/${FILENAME}"

echo ">>> Uploading $FILE -> $DEST" >&2
rclone copyto "$FILE" "$DEST" --progress 1>&2

echo ">>> Creating public link" >&2
URL="$(rclone link "$DEST")"

if [ -z "$URL" ]; then
  echo "ERROR: rclone link returned an empty URL" >&2
  exit 4
fi

echo "$URL"
