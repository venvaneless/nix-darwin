# /Users/ven/dotfiles/nix/scripts/rsync-all.sh

#!/bin/bash
set -euo pipefail

SCRIPT_DIR="/Users/ven/dotfiles/nix/scripts"

# ENABLED SCRIPTS (only these run)
# Add or remove entries here to control what rsync-all runs
# ------------------------------------------------------------
ENABLED_SCRIPTS=(
  "rsync-zed.sh"
  "rsync-obsidian.sh"
  "rsync-vaultwarden.sh"
)

echo "▶ Running selected backup scripts…"

for script_name in "${ENABLED_SCRIPTS[@]}"; do
    script="$SCRIPT_DIR/$script_name"

    if [ ! -f "$script" ]; then
        echo "Skipping $script_name (does not exist)"
        continue
    fi

    if [ ! -x "$script" ]; then
        echo "Skipping $script_name (not executable)"
        continue
    fi

    echo "----------------------------------------"
    echo "Running: $script_name"
    "$script"
done

echo "✔ Selected backup scripts complete."
