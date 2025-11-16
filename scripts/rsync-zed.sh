# /Users/ven/dotfiles/nix/scripts/rsync-zed.sh

#!/bin/bash
set -euo pipefail

SRC="/Users/ven/dotfiles/apps/zed"
DEST="/Users/ven/iCloudDocs/my-system/01-app-data/zed"

CHANGES=$(rsync -avh --delete --dry-run "$SRC/" "$DEST/" | grep -v '/$' | wc -l)

if [ "$CHANGES" -eq 0 ]; then
  echo "Zed: no changes, skipping."
  exit 0
fi

echo "Zed: syncing $CHANGES changed files…"
mkdir -p "$DEST"
rsync -avh --delete "$SRC/" "$DEST/"
echo "Zed: synced."
