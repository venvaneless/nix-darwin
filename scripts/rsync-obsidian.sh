# /Users/ven/dotfiles/nix/scripts/rsync-obsidian.sh

#!/bin/bash
set -euo pipefail

# SOURCE: Obsidian iCloud vaults (REAL LOCATION)
# ------------------------------------------------------------
SRC="/Users/ven/Library/Mobile Documents/iCloud~md~obsidian/Documents"
DEST="/Users/ven/iCloudDocs/my-system/01-app-data/obsidian"

echo "▶ Obsidian backup starting…"

# 1. Ensure the source exists
# ------------------------------------------------------------
if [ ! -d "$SRC" ]; then
  echo "✖ ERROR: Obsidian source folder does not exist:"
  echo "  $SRC"
  exit 1
fi

# 2. Ensure the destination exists
# ------------------------------------------------------------
if [ ! -d "$DEST" ]; then
  echo "→ Destination does not exist, creating it…"
  mkdir -p "$DEST"
fi

# 3. Dry-run comparison
# ------------------------------------------------------------
DRY_OUTPUT=$(rsync -avh --delete --dry-run "$SRC/" "$DEST/")
CHANGES=$(echo "$DRY_OUTPUT" | grep -v '/$' | wc -l | tr -d ' ')

if [ "$CHANGES" -eq 0 ]; then
  echo "✔ No changes detected. Backup skipped."
  exit 0
fi

echo "→ $CHANGES changes detected:"
echo "$DRY_OUTPUT"

# 4. Perform backup
# ------------------------------------------------------------
echo "→ Syncing now…"
rsync -avh --delete "$SRC/" "$DEST/"

echo "✔ Obsidian backup completed."
