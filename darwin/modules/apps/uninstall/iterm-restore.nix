# DARWIN: ITERM2 USER-DATA FULL RESTORE (REVERSE OF SYMLINK MODULE)
# ===================================================================
# Restores ALL iTerm2 config data back to native macOS locations:
#   - Removes symlinks in Application Support/iTerm2
#   - Copies real files from dotIterm back to Application Support/iTerm2
#   - Restores com.googlecode.iterm2.plist to a REAL file
#   - Never creates new symlinks
#   - Leaves dotIterm intact so you can delete it manually
# ===================================================================

{ config, lib, pkgs, ... }:

let
  home      = config.home.homeDirectory;
  asIterm   = "${home}/Library/Application Support/iTerm2";
  dotIterm  = "/Users/ven/dotfiles/apps/iterm";

  plist    = "${home}/Library/Preferences/com.googlecode.iterm2.plist";
  dotPlist = "${dotIterm}/com.googlecode.iterm2.plist";
in
{
  home.activation.itermRestore =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Restoring iTerm2 config from dotfiles → real filesystem..."

      # ----------------------------------------------------------------
      # Ensure runtime directory exists
      # ----------------------------------------------------------------
      if [ -d "${dotIterm}" ] && [ ! -d "${asIterm}" ]; then
        echo "Creating Application Support/iTerm2..."
        mkdir -p "${asIterm}"
      fi

      # ----------------------------------------------------------------
      # Convert symlinks inside Application Support/iTerm2 → real files
      # ----------------------------------------------------------------
      if [ -d "${asIterm}" ]; then
        echo "Converting symlinks in Application Support/iTerm2..."

        while IFS= read -r -d $'\0' item; do
          name="$(basename "$item")"
          target="$(readlink "$item" || true)"

          case "$target" in
            "${dotIterm}/"*)
              echo "  - Restoring real file/dir: $name"
              tmp="${asIterm}/.$name.restore-tmp"
              rm -rf "$tmp"

              if [ -e "$target" ]; then
                cp -a "$target" "$tmp"
                rm -f "$item"
                mv "$tmp" "${asIterm}/$name"
              else
                echo "    (Warning: symlink target missing, removing only)"
                rm -f "$item"
              fi
              ;;
            *)
              echo "  - Removing unrelated symlink: $name"
              rm -f "$item"
              ;;
          esac
        done < <(find "${asIterm}" -maxdepth 1 -mindepth 1 -type l -print0)
      fi

      # ----------------------------------------------------------------
      # Copy missing items from dotIterm → Application Support/iTerm2
      # ----------------------------------------------------------------
      if [ -d "${dotIterm}" ]; then
        echo "Restoring remaining files from dotIterm..."

        for item in "${dotIterm}"/*; do
          name="$(basename "$item")"

          # Skip plist (handled separately)
          [ "$name" = "com.googlecode.iterm2.plist" ] && continue

          if [ ! -e "${asIterm}/$name" ]; then
            echo "  - Copying: $name"
            cp -a "$item" "${asIterm}/$name"
          else
            echo "  - Already present: $name"
          fi
        done
      fi

      # ----------------------------------------------------------------
      # Restore Preferences/com.googlecode.iterm2.plist as REAL FILE
      # ----------------------------------------------------------------
      echo "Restoring Preferences plist..."

      if [ -L "${plist}" ]; then
        echo "  - Converting plist symlink → real file"
        rm -f "${plist}"
        if [ -f "${dotPlist}" ]; then
          cp -a "${dotPlist}" "${plist}"
        else
          echo "  - dotPlist missing; creating empty plist"
          : > "${plist}"
        fi

      elif [ ! -e "${plist}" ]; then
        echo "  - plist missing; restoring from dotPlist (if exists)"
        if [ -f "${dotPlist}" ]; then
          cp -a "${dotPlist}" "${plist}"
        else
          : > "${plist}"
        fi

      else
        echo "  - plist already a real file; leaving unchanged"
      fi

      echo "✔ iTerm2 restore complete."
    '';
}
