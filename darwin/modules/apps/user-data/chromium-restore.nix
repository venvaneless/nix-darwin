# DARWIN: CHROMIUM USER-DATA FULL RESTORE (REVERSE OF SYMLINK MODULE)
# ===================================================================
# Purpose:
#   - Convert all Chromium symlinks → real files/dirs
#   - Copy contents back from dotChromium to Application Support
#   - Restore real plist in Preferences
#   - NO new symlinks created
#   - Leaves dotChromium intact for manual cleanup later
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
      echo "Restoring Chromium data from dotfiles → real filesystem..."

      # ----------------------------------------------------------------
      # Ensure runtime directory exists if dotChromium exists
      # ----------------------------------------------------------------
      if [ -d "${dotChromium}" ] && [ ! -d "${asChromium}" ]; then
        echo "Creating Application Support/Chromium..."
        mkdir -p "${asChromium}"
      fi

      # ----------------------------------------------------------------
      # Convert symlinks inside Application Support/Chromium → real files
      # ----------------------------------------------------------------
      if [ -d "${asChromium}" ]; then
        echo "Converting symlinks inside Application Support/Chromium..."

        while IFS= read -r -d $'\0' item; do
          base="$(basename "$item")"
          target="$(readlink "$item" || true)"

          case "$target" in
            "${dotChromium}/"*)
              echo "  - Restoring: $base"
              tmp="${asChromium}/.$base.restore-tmp"
              rm -rf "$tmp"
              if [ -e "$target" ]; then
                cp -a "$target" "$tmp"
                rm -f "$item"
                mv "$tmp" "${asChromium}/$base"
              else
                echo "    (Warning: target missing, removing symlink only)"
                rm -f "$item"
              fi
              ;;
            *)
              echo "  - Removing symlink not pointing to dotChromium: $base"
              rm -f "$item"
              ;;
          esac
        done < <(find "${asChromium}" -maxdepth 1 -mindepth 1 -type l -print0)
      fi

      # ----------------------------------------------------------------
      # Ensure anything in dotChromium exists in Application Support
      # ----------------------------------------------------------------
      if [ -d "${dotChromium}" ]; then
        echo "Copying missing items from dotChromium → Application Support..."

        for item in "${dotChromium}"/*; do
          base="$(basename "$item")"

          if [ "$base" = "org.chromium.Chromium.plist" ]; then
            continue
          fi

          if [ ! -e "${asChromium}/$base" ]; then
            echo "  - Restoring: $base"
            cp -a "$item" "${asChromium}/$base"
          else
            echo "  - Exists already: $base"
          fi
        done
      fi

      # ----------------------------------------------------------------
      # Restore real plist in Preferences
      # ----------------------------------------------------------------
      echo "Restoring Preferences/org.chromium.Chromium.plist..."

      if [ -L "${plist}" ]; then
        echo "  - Converting symlink plist → real file"
        rm -f "${plist}"

        if [ -f "${dotPlist}" ]; then
          cp -a "${dotPlist}" "${plist}"
        else
          : > "${plist}"
        fi

      elif [ ! -e "${plist}" ]; then
        echo "  - plist missing, restoring from dotPlist (if exists)"
        if [ -f "${dotPlist}" ]; then
          cp -a "${dotPlist}" "${plist}"
        else
          : > "${plist}"
        fi
      else
        echo "  - plist already real, leaving untouched"
      fi

      echo "✔ Chromium reverse-symlink restore COMPLETED."
    '';
}
