# DARWIN: CHROMIUM USER-DATA FULL RESTORE (REVERSE OF SYMLINK MODULE)
# ===================================================================
# Purpose:
#   - Stop using ~/dotfiles/apps/chromium as "source of truth"
#   - Remove symlinks inside ~/Library/Application Support/Chromium
#   - Materialize real files/dirs there again (copied from dotChromium)
#   - Fix org.chromium.Chromium.plist back to a real file in Preferences
#   - NO new symlinks are created
#   - dotChromium is left intact (you can delete it manually afterwards)
# ===================================================================

{ config, lib, pkgs, ... }:

let
  home        = config.home.homeDirectory;
  asChromium  = "${home}/Library/Application Support/Chromium";
  dotChromium = "/Users/ven/dotfiles/apps/chromium";

  plist    = "${home}/Library/Preferences/org.chromium.Chromium.plist";
  dotPlist = "${dotChromium}/org.chromium.Chromium.plist";
in
{
  home.activation.chromiumRestore =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Restoring Chromium data from dotfiles → real files..."

      # ----------------------------------------------------------------
      # 0. Sanity: ensure runtime dir exists if we have dotfiles
      # ----------------------------------------------------------------
      if [ -d "${dotChromium}" ] && [ ! -d "${asChromium}" ]; then
        echo "Creating Application Support/Chromium..."
        mkdir -p "${asChromium}"
      fi

      if [ ! -d "${asChromium}" ]; then
        echo "No Application Support/Chromium directory present. Nothing to restore."
      fi

      # ----------------------------------------------------------------
      # 1. Convert symlinks in Application Support/Chromium → real files
      # ----------------------------------------------------------------
      if [ -d "${asChromium}" ]; then
        echo "Converting symlinks inside Application Support/Chromium to real files..."

        # Handle both files and directories that are symlinks
        while IFS= read -r -d '' item; do
          base="$(basename "$item")"
          target="$(readlink "$item" || true)"

          # If the symlink points into dotChromium and target exists,
          # copy the real contents back and drop the symlink.
          case "$target" in
            "${dotChromium}/"*)
              echo "  - Restoring from dotfiles: $base"
              # Use a temp name to avoid overwriting issues
              tmp="${asChromium}/.$base.restore-tmp"
              rm -rf "$tmp"
              if [ -e "$target" ]; then
                cp -a "$target" "$tmp"
                rm -f "$item"
                mv "$tmp" "${asChromium}/$base"
              else
                echo "    (Warning: target $target does not exist, removing symlink only)"
                rm -f "$item"
              fi
              ;;
            *)
              echo "  - Symlink not pointing into dotChromium, removing only: $base"
              rm -f "$item"
              ;;
          esac
        done < <(find "${asChromium}" -maxdepth 1 -mindepth 1 -type l -print0)
      fi

      # ----------------------------------------------------------------
      # 2. Ensure anything still in dotChromium exists in Application Support
      # ----------------------------------------------------------------
      if [ -d "${dotChromium}" ]; then
        echo "Ensuring all dotfiles/apps/chromium items are present in Application Support..."

        for item in "${dotChromium}"/*; do
          base="$(basename "$item")"

          # Skip plist here; handled separately
          if [ "$base" = "org.chromium.Chromium.plist" ]; then
            continue
          fi

          if [ ! -e "${asChromium}/$base" ]; then
            echo "  - Copying missing item: $base"
            cp -a "$item" "${asChromium}/$base"
          else
            echo "  - Already exists in Application Support, leaving as-is: $base"
          fi
        done
      else
        echo "dotChromium (${dotChromium}) does not exist; nothing to copy back."
      fi

      # ----------------------------------------------------------------
      # 3. Plist handling: make it a REAL file again
      # ----------------------------------------------------------------
      echo "Restoring org.chromium.Chromium.plist to a real file (no symlink)..."

      # If plist is a symlink, convert to real file from dotPlist if possible
      if [ -L "${plist}" ]; then
        echo "  - Plist is a symlink, converting to real file..."
        rm -f "${plist}"
        if [ -f "${dotPlist}" ]; then
          cp -a "${dotPlist}" "${plist}"
          echo "  - Plist restored from dotPlist."
        else
          echo "  - dotPlist missing; creating empty plist file."
          : > "${plist}"
        fi
      elif [ ! -e "${plist}" ]; then
        # No plist at all → copy from dotPlist if available
        if [ -f "${dotPlist}" ]; then
          echo "  - Plist missing; copying from dotPlist."
          cp -a "${dotPlist}" "${plist}"
        else
          echo "  - Plist missing and dotPlist not found; creating empty plist."
          : > "${plist}"
        fi
      else
        echo "  - Plist is already a real file; leaving as-is."
      fi

      echo "Chromium reverse-symlink restore complete."
      echo "You can now stop using chromium-symlinks.nix and optionally remove ${dotChromium} manually."
    '';
}
