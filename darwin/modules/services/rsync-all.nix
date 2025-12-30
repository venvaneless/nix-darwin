# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/rsync-all.nix
#
# SYSTEM: RSYNC-ALL (SELECTIVE DISPATCHER)
# ============================================================
# Purpose:
#   - Run ONLY explicitly enabled rsync backup scripts during `drs`
#   - Keep the selection logic declarative (in Nix), not in a .sh wrapper
#
# Script location (outside Nix store):
#   /Users/ven/.config/nix/nix-scripts/rsync-*.sh
#
# How to enable / disable individual backups:
#   - Edit the ENABLED_SCRIPTS list below (comment/uncomment entries)
#   - AND/OR remove executable bit from a script to disable it:
#       chmod -x /Users/ven/.config/nix/nix-scripts/rsync-foo.sh
#
# Safety guarantees (DISPATCHER ONLY):
#   - Does NOT touch iCloud directly
#   - Does NOT modify filesystem state (no rm/mv/ln) in the dispatcher
#   - Does NOT interact with FileProvider
#   - Does NOT affect system permissions
#   - Does NOT fail or block activation (errors are logged and ignored)
#
# Notes:
#   - Individual rsync-* scripts can still do dangerous things. This
#     dispatcher will not add any such behavior on its own.
# ============================================================

{ lib, ... }:

{
  # ------------------------------------------------------------
  # DARWIN: POST-ACTIVATION BACKUP DISPATCHER
  # ------------------------------------------------------------
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    set -euo pipefail

    LOG_PREFIX="[system][rsync-all]"
    SCRIPT_DIR="/Users/ven/.config/nix/nix-scripts"

    echo "$LOG_PREFIX Starting selective backups"
    echo "$LOG_PREFIX DARWIN_REBUILD_REASON=${DARWIN_REBUILD_REASON:-<unset>}"

    # ------------------------------------------------------------
    # SAFETY GUARD — NEVER BLOCK ACTIVATION
    # ------------------------------------------------------------
    # If anything in this dispatcher fails, we log and continue.
    # This ensures `drs` does not hang on dispatcher-level issues.
    # ------------------------------------------------------------
    dispatcher_main() {
      # ----------------------------------------------------------
      # SAFETY GUARD — SKIP DURING darwin-rebuild check
      # ----------------------------------------------------------
      # Some setups expose DARWIN_REBUILD_REASON during activation.
      # If it is present and equals "check", we do nothing.
      # If it is unset, we assume "switch" (safe default here).
      # ----------------------------------------------------------
      if [ "${DARWIN_REBUILD_REASON:-switch}" = "check" ]; then
        echo "$LOG_PREFIX Skipping backups during darwin-rebuild check"
        return 0
      fi

      # ----------------------------------------------------------
      # SAFETY GUARD — ENSURE SCRIPT DIRECTORY EXISTS
      # ----------------------------------------------------------
      if [ ! -d "$SCRIPT_DIR" ]; then
        echo "$LOG_PREFIX Script directory not found: $SCRIPT_DIR"
        return 0
      fi

      # ----------------------------------------------------------
      # ENABLED SCRIPTS (ONLY THESE RUN)
      # ----------------------------------------------------------
      # Toggle scripts by commenting entries here.
      # A script must also be executable to run.
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
        # If a script fails, we log it and continue.
        # If a script hangs, it can still hang the rebuild — that
        # must be fixed inside the script (timeouts/excludes).
        # --------------------------------------------------------
        "$script" || echo "$LOG_PREFIX WARNING: $script_name failed (ignored)"
      done

      echo "$LOG_PREFIX Selected backup scripts complete"
    }

    dispatcher_main || echo "$LOG_PREFIX WARNING: dispatcher failed (ignored)"
  '';
}
