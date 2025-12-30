# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/rsync-all.nix
#
# SYSTEM: RSYNC-ALL (SELECTIVE BACKUP DISPATCHER)
# ============================================================
# Purpose:
#   - Run ONLY explicitly enabled rsync-* backup scripts
#     during `darwin-rebuild switch`
#
# Backup scripts location (outside Nix store):
#   /Users/ven/.config/nix/nix-scripts/rsync-*.sh
#
# How to enable / disable backups:
#   - Comment / uncomment entries in ENABLED_SCRIPTS below
#   - A script must also be executable to run
#
# Safety guarantees (DISPATCHER ONLY):
#   - Does NOT touch iCloud data
#   - Does NOT modify filesystem state (no rm/mv/ln)
#   - Does NOT interact with FileProvider
#   - Does NOT change system permissions
#   - Does NOT block or fail activation
# ============================================================

{ lib, pkgs, ... }:

let
  rsyncAllScript = pkgs.writeShellScriptBin "rsync-all" ''
    #!/bin/bash
    set -euo pipefail

    LOG_PREFIX="[system][rsync-all]"
    SCRIPT_DIR="/Users/ven/.config/nix/nix-scripts"

    echo "$LOG_PREFIX Starting selective backups"
    echo "$LOG_PREFIX DARWIN_REBUILD_REASON=${DARWIN_REBUILD_REASON:-<unset>}"

    # ----------------------------------------------------------
    # SAFETY GUARD — RUN ONLY DURING darwin-rebuild switch
    # ----------------------------------------------------------
    if [ "${DARWIN_REBUILD_REASON:-switch}" != "switch" ]; then
      echo "$LOG_PREFIX Skipping backups (reason=${DARWIN_REBUILD_REASON:-unknown})"
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

      # --------------------------------------------------------
      # EXECUTION — NEVER FAIL ACTIVATION
      # --------------------------------------------------------
      "$script" || echo "$LOG_PREFIX WARNING: $script_name failed (ignored)"
    done

    echo "$LOG_PREFIX Selected backup scripts complete"
  '';
in
{
  # ------------------------------------------------------------
  # DARWIN ACTIVATION HOOK
  # ------------------------------------------------------------
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running rsync-all (system)"
    ${rsyncAllScript}/bin/rsync-all || echo "rsync-all failed (ignored)"
  '';
}
