# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/rsync-all-old.nix
#
# SYSTEM: RSYNC-ALL WRAPPER
# ============================================================
# Embeds your rsync-all.sh script into the Nix store.
# This version simply calls all rsync-*.sh scripts that
# you maintain outside Nix.
# ============================================================

{ lib, pkgs, ... }:

let
  rsyncScript = pkgs.writeShellScriptBin "rsync-all" ''
    #!/bin/bash
    set -euo pipefail

    SCRIPT_DIR="/Users/ven/.config/nix/nix-scripts"

    echo "▶ Running all app backup scripts…"

    for script in "$SCRIPT_DIR"/rsync-*.sh; do
      # Skip this wrapper itself if present
      [ "$script" = "$SCRIPT_DIR/rsync-all-old.sh" ] && continue

      if [ -x "$script" ]; then
        echo "----------------------------------------"
        echo "Running: $(basename "$script")"
        "$script"
      else
        echo "Skipping $script (not executable)"
      fi
    done

    echo "✔ All backup scripts complete."
  '';
in
{
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running rsync-all (system)"
    ${rsyncScript}/bin/rsync-all || echo "rsync-all failed (ignored)"
  '';
}
