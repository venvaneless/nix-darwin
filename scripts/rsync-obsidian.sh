#!/bin/bash
set -euo pipefail

VAULT="/Users/ven/dotfiles/apps/Obsidian"
DEST="/Users/ven/iCloudDocs/backup/apps/obsidian"

# Dry-run to detect changed files
CHANGES=$(rsync -avh --delete --dry-run "$VAULT/" "$DEST/" | grep -v '/$' | wc -l)

if [ "$CHANGES" -eq 0 ]; then
  echo "Obsidian: no changes, skipping."
  exit 0
fi

echo "Obsidian: syncing $CHANGES changed files…"
mkdir -p "$DEST"
rsync -avh --delete "$VAULT/" "$DEST/"
echo "Obsidian: synced."
