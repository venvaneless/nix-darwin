# /Users/ven/dotfiles/nix/scripts/rsync-vaultwarden.sh

#!/bin/bash
set -euo pipefail

SRC="/Users/ven/dotfiles/containers/vaultwarden"
DEST="/Users/ven/iCloudDocs/my-system/04-containers/vaultwarden"

echo "▶ Vaultwarden backup starting…"

# ------------------------------------------------------------
# 1. Ensure the source exists
# ------------------------------------------------------------
if [ ! -d "$SRC" ]; then
  echo "✖ ERROR: Source folder does not exist: $SRC"
  exit 1
fi

# ------------------------------------------------------------
# 2. Ensure the destination exists (empty or not)
# ------------------------------------------------------------
if [ ! -d "$DEST" ]; then
  echo "→ Destination does not exist, creating it…"
  mkdir -p "$DEST"
fi

# ------------------------------------------------------------
# 3. Dry-run to detect changes
# ------------------------------------------------------------
DRY_OUTPUT=$(rsync -avh --delete --dry-run "$SRC/" "$DEST/")
CHANGES=$(echo "$DRY_OUTPUT" | grep -v '/$' | wc -l | tr -d ' ')

if [ "$CHANGES" -eq 0 ]; then
  echo "✔ No changes detected. Backup skipped."
  exit 0
fi

echo "→ $CHANGES changes detected:"
echo "$DRY_OUTPUT"

# ------------------------------------------------------------
# 4. Perform the real sync
# ------------------------------------------------------------
echo "→ Syncing now…"
rsync -avh --delete "$SRC/" "$DEST/"

echo "✔ Vaultwarden backup completed."
