# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/chromium-symlinks.nix
# 
# DARWIN: CHROMIUM USER-DATA + PROFILE SYMLINKING
# ============================================================
# Source of truth:
#     /Users/ven/ven-dots/user-data/apps/chromium
#
# Runtime paths:
#     ~/Library/Application Support/Chromium
#     ~/Library/Preferences/org.chromium.Chromium.plist
#
# Responsibilities:
#   - Ensure ven-dots/apps/chromium exists
#   - Move real Chromium profile into ven-dots if present
#   - Ensure Application Support/Chromium is a symlink → ven-dots/apps/chromium
#   - Move any new system-created files/dirs into source-of-truth
#   - Ensure plist is moved + symlinked just like Zed’s plist handling
#   - Never overwrite dotfiles unless file does not exist on ven-dots
# ============================================================

{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;

  dotChromium = "/Users/ven/ven-dots/user-data/apps/chromium";
  asChromium  = "${home}/Library/Application Support/Chromium";

  prefPlist   = "${home}/Library/Preferences/org.chromium.Chromium.plist";
  dotPlist    = "${dotChromium}/org.chromium.Chromium.plist";
in
{
  home.activation.chromiumUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing Chromium user-data..."

      # ------------------------------------------------------------
      # Ensure dotfiles root exists
      # ------------------------------------------------------------
      if [ ! -d "${dotChromium}" ]; then
        echo "Creating Chromium dotfiles root → ${dotChromium}"
        mkdir -p "${dotChromium}"

        # If Application Support/Chromium exists, copy its contents
        if [ -d "${asChromium}" ] && [ ! -L "${asChromium}" ]; then
          echo "Copying existing Application Support → dotfiles"
          cp -a "${asChromium}/." "${dotChromium}/" 2>/dev/null || true
        fi

        # Copy plist if it exists
        if [ -f "${prefPlist}" ]; then
          echo "Copying existing plist → dotfiles"
          cp -a "${prefPlist}" "${dotPlist}" || true
        fi
      fi


      # ------------------------------------------------------------
      # Ensure Application Support/Chromium is a REAL DIR before symlinking
      # ------------------------------------------------------------
      if [ -L "${asChromium}" ]; then
        echo "Fixing: Application Support/Chromium must not be a symlink pre-migration"
        rm -f "${asChromium}"
      fi

      if [ -d "${asChromium}" ]; then
        echo "Found real Chromium directory → preparing for migration"
      fi


      # ------------------------------------------------------------
      # Move system-created files/dirs from AS → dotfiles (same logic as Zed)
      # ------------------------------------------------------------
      if [ -d "${asChromium}" ] && [ ! -L "${asChromium}" ]; then
        echo "Migrating Chromium items into dotfiles..."

        for item in "${asChromium}"/*; do
          [ -e "$item" ] || continue
          name="$(basename "$item")"

          if [ -e "${dotChromium}/$name" ]; then
            echo "  Skipping existing: $name"
            rm -rf "$item"
            ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
            continue
          fi

          echo "  Moving: $name"
          mv "$item" "${dotChromium}/$name"
          ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
        done
      fi


      # ------------------------------------------------------------
      # Recreate Application Support/Chromium as a symlink → dotfiles
      # ------------------------------------------------------------
      rm -rf "${asChromium}"
      ln -sfn "${dotChromium}" "${asChromium}"
      echo "Symlink created: Chromium → ${dotChromium}"


      # ------------------------------------------------------------
      # PLIST HANDLING (same style as Zed)
      # ------------------------------------------------------------
      echo "Managing Chromium plist..."

      # If real plist exists and source-of-truth copy is missing → move it
      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPlist}" ]; then
        echo "Moving real plist → dotfiles"
        mv "${prefPlist}" "${dotPlist}"
      fi

      # Ensure dotfiles plist exists
      if [ ! -f "${dotPlist}" ]; then
        echo "Creating empty plist in dotfiles"
        : > "${dotPlist}"
      fi

      # Ensure Preferences plist symlink exists
      ln -sfn "${dotPlist}" "${prefPlist}"
      echo "Plist symlinked: ${prefPlist} → ${dotPlist}"

      echo "Chrome: User-data sync complete"
    '';
}
