# /Users/ven/dotfiles/nix/darwin/modules/services/rsync-all.nix
#
# SYSTEM: RSYNC-ALL WRAPPER
# ============================================================
# Embeds your rsync-all.sh script into the Nix store.
# This version simply calls all rsync-*.sh scripts that
# you maintain outside Nix.
# ============================================================

{ config, pkgs, ... }:

let
  rsyncScript = pkgs.writeShellScriptBin "rsync-all" ''
    #!/bin/bash
    set -euo pipefail

    SCRIPT_DIR="/Users/ven/dotfiles/nix/scripts"

    echo "▶ Running all app backup scripts…"

    for script in "$SCRIPT_DIR"/rsync-*.sh; do
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
  '';
in
{
  config.system.activationScripts.rsyncAll.text = ''
    echo "Running system rsync all..."
    ${rsyncScript}/bin/rsync-all
  '';
}
