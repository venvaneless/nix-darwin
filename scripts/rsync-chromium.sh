# /Users/ven/dotfiles/nix/scripts/rsync-chromium.sh
# 
# #!/bin/bash
# 
# Chromium: BACKUP SCRIPT
# ============================================================
# # This script synchronizes your Chromium configuration stored in
# /Users/ven/dotfiles/apps/chromium with a backup copy in
# /Users/ven/iCloudDocs/my-system/01-app_data/chromium.  It follows
# the same pattern as rsync-zed.sh and rsync-iterm.sh by performing
# a dry-run first, reporting the number of changes, and then performing
# the actual rsync if needed.  If the destination directory
# doesn’t exist, it will be created.
# ============================================================

set -euo pipefail

SRC="/Users/ven/dotfiles/apps/chromium"
DEST="/Users/ven/iCloudDocs/my-system/01-app_data/chromium"

echo "▶ Chromium backup starting…"

# 1. Ensure the source exists
if [ ! -d "$SRC" ]; then
  echo "✖ ERROR: Source folder does not exist: $SRC"
  exit 1
fi

# 2. Ensure the destination exists
if [ ! -d "$DEST" ]; then
  echo "→ Destination does not exist, creating it…"
  mkdir -p "$DEST"
fi

# 3. Dry-run to detect changes
DRY_OUTPUT=$(rsync -avh --delete --dry-run "$SRC/" "$DEST/")
CHANGES=$(echo "$DRY_OUTPUT" | grep -v '/$' | wc -l | tr -d ' ')

if [ "$CHANGES" -eq 0 ]; then
  echo "✔ No changes detected. Backup skipped."
  exit 0
fi

echo "→ $CHANGES changes detected:"
echo "$DRY_OUTPUT"

# 4. Perform the real sync
echo "→ Syncing now…"
rsync -avh --delete "$SRC/" "$DEST/"

echo "✔ Chromium backup completed."
