#!/bin/bash
set -euo pipefail

SCRIPT_DIR="/Users/ven/dotfiles/nix/scripts"

echo "▶ Running all app backup scripts…"

for script in "$SCRIPT_DIR"/rsync-*.sh; do
    # Skip this script itself if the name matches
    [ "$script" = "$SCRIPT_DIR/rsync-all.sh" ] && continue

    if [ -x "$script" ]; then
        echo "----------------------------------------"
        echo "Running: $(basename "$script")"
        "$script"
    else
        echo "Skipping $script (not executable)"
    fi
done

echo "✔ All backup scripts complete."
