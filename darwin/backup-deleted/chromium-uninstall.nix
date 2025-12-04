# DARWIN: CHROMIUM USER-DATA RESTORE MODULE
# ============================================
# Purpose:
#   - Remove symlinks in ~/Library/Application Support/Chromium
#   - Move back real files and directories from ~/dotfiles/apps/chromium
#   - Preserve fragile login-related DBs in place if they exist
#   - Never delete anything
#   - No re-symlinking; this is a one-way restore
# ============================================

{ config, lib, pkgs, ... }:

let
  home        = config.home.homeDirectory;
  asChromium  = "${home}/Library/Application Support/Chromium";
  dotChromium = "/Users/ven/dotfiles/apps/chromium";

  fragile = ''
Cookies
Cookies-journal
Network Persistent State
Secure Preferences
TransportSecurity
'';
in
{
  home.activation.chromiumRestore =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Restoring Chromium user-data..."

      # ------------------------------------------------------------
      # Helper: fragile file test
      # ------------------------------------------------------------
      is_fragile() {
        case "$1" in
          "Cookies" | \
          "Cookies-journal" | \
          "Network Persistent State" | \
          "Secure Preferences" | \
          "TransportSecurity")
            return 0
            ;;
        esac
        return 1
      }

      # ------------------------------------------------------------
      # Ensure runtime directory exists
      # ------------------------------------------------------------
      echo "Ensuring Application Support/Chromium exists..."
      mkdir -p "${asChromium}"

      # ------------------------------------------------------------
      # Remove all symlinks inside Application Support/Chromium
      # ------------------------------------------------------------
      echo "Removing symlinks inside Chromium data dir..."
      while IFS= read -r item; do
        base="$(basename "$item")"

        # Skip fragile files; we never remove or overwrite them
        if is_fragile "$base"; then
          echo "Keeping fragile file untouched: $base"
          continue
        fi

        # If it's a symlink, remove it — but keep target in dotfiles
        if [ -L "$item" ]; then
          echo "Removing symlink: $base"
          rm -f "$item"
        fi
      done < <(find "${asChromium}" -maxdepth 1 -mindepth 1)

      # ------------------------------------------------------------
      # Move files/directories back from dotfiles → Application Support
      # ------------------------------------------------------------
      echo "Restoring files from dotfiles/apps/chromium → Application Support..."

      for item in "${dotChromium}"/*; do
        base="$(basename "$item")"

        # Skip plist — Chromium keeps it in Preferences, not here
        if [ "$base" = "org.chromium.Chromium.plist" ]; then
          continue
        fi

        # Fragile DBs must remain wherever they currently are
        if is_fragile "$base"; then
          echo "Skipping fragile (not restored from dotfiles): $base"
          continue
        fi

        # If destination doesn't exist, restore it
        if [ ! -e "${asChromium}/$base" ]; then
          echo "Restoring: $base"
          cp -a "$item" "${asChromium}/$base"
        else
          echo "Already exists, not overwriting: $base"
        fi
      done

      echo "Chromium restore complete."
    '';
}
