# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/rsync-all.nix
#
# SYSTEM: RSYNC-ALL (SELECTIVE DISPATCHER)
# ============================================================
# Purpose:
#   - Run ONLY explicitly enabled rsync backup scripts during `drs`
#
# Script location (outside Nix store):
#   /Users/ven/.config/nix/nix-scripts/rsync-*.sh
#
# Safety guarantees (DISPATCHER ONLY):
#   - Does NOT touch iCloud directly
#   - Does NOT modify filesystem state (no rm/mv/ln)
#   - Does NOT interact with FileProvider
#   - Does NOT affect system permissions
#   - Does NOT fail or block activation
# ============================================================

{ lib, ... }:

{
  # ------------------------------------------------------------
  # DARWIN: POST-ACTIVATION BACKUP DISPATCHER
  # ------------------------------------------------------------
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    #!/bin/bash
    set -euo pipefail

    LOG_PREFIX="[system][rsync-all]"
    SCRIPT_DIR="/Users/ven/.config/nix/nix-scripts"

    echo "$LOG_PREFIX Starting selective backups"
    echo "$LOG_PREFIX DARWIN_REBUILD_REASON=''${DARWIN_REBUILD_REASON:-<unset>}"

    # ----------------------------------------------------------
    # SAFETY GUARD — SKIP DURING darwin-rebuild check
    # ----------------------------------------------------------
    if [ "''${DARWIN_REBUILD_REASON:-switch}" = "check" ]; then
      echo "$LOG_PREFIX Skipping backups during darwin-rebuild check"
      exit 0
    fi

    # ----------------------------------------------------------
    # SAFETY GUARD — ENSURE SCRIPT DIRECTORY EXISTS
    # ----------------------------------------------------------
    if [ ! -d "$SCRIPT_DIR" ]; then
      echo "$LOG_PREFIX Script directory not found: $SCRIPT_DIR"
      exit 0
    fi

    # ----------------------------------------------------------
    # ENABLED SCRIPTS (ONLY THESE RUN)
    # ----------------------------------------------------------
    ENABLED_SCRIPTS=(
      # "rsync-a_better_finder_attributes.sh"
      # "rsync-a_better_finder_rename.sh"
      "rsync-chromium.sh"
      # "rsync-espanso.sh"
      "rsync-iterm.sh"
      # "rsync-obsidian.sh"
      # "rsync-paste.sh"
      "rsync-vaultwarden.sh"
      # "rsync-vlc.sh"
      # "rsync-yate.sh"
      "rsync-zed.sh"
    )

    echo "$LOG_PREFIX Running selected backup scripts"

    for script_name in "''${ENABLED_SCRIPTS[@]}"; do
      script="$SCRIPT_DIR/$script_name"

      if [ ! -f "$script" ]; then
        echo "$LOG_PREFIX Skipping $script_name (does not exist)"
        continue
      fi

      if [ ! -x "$script" ]; then
        echo "$LOG_PREFIX Skipping $script_name (not executable)"
        continue
      fi

      echo "----------------------------------------"
      echo "$LOG_PREFIX Running: $script_name"

      "$script" || echo "$LOG_PREFIX WARNING: $script_name failed (ignored)"
    done

    echo "$LOG_PREFIX Selected backup scripts complete"
  '';
}
