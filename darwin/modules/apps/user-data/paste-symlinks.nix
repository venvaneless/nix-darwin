# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/paste-symlinks.nix
#
# DARWIN: PASTE USER-DATA
# ============================================================
# Paste is a clipboard manager for macOS.
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/paste
#
# Runtime locations:
#   ~/Library/Application Support/com.wiheads.paste-direct/
#   ~/Library/Preferences/com.wiheads.paste-direct.plist
#
# Responsibilities:
#   - Ensure dotfiles folder exists
#   - Move existing Application Support files into dotfiles
#   - Move Preferences plist into dotfiles
#   - Recreate original locations
#   - Symlink files back to their original paths
#
# IMPORTANT:
#   - No symlinks are ever created inside the dotfiles folder
#   - Only individual files are symlinked (never whole directories)
# ============================================================

{ config, lib, ... }:

let
  # ------------------------------------------------------------
  # PATH ROOTS
  # ------------------------------------------------------------
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  # ------------------------------------------------------------
  # APP IDENTIFIERS
  # ------------------------------------------------------------
  appFolder = "paste";

  asDirName = "com.wiheads.paste-direct";

  # ------------------------------------------------------------
  # RUNTIME PATHS
  # ------------------------------------------------------------
  asPath    = "${home}/Library/Application Support/${asDirName}";
  prefPlist = "${home}/Library/Preferences/com.wiheads.paste-direct.plist";

  # ------------------------------------------------------------
  # DOTFILES PATHS (SOURCE OF TRUTH)
  # ------------------------------------------------------------
  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.wiheads.paste-direct.plist";
in
{
  home.activation.pasteUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: Paste"

      # ------------------------------------------------------------
      # DOTFILES: ENSURE ROOT EXISTS
      # ------------------------------------------------------------
      mkdir -p "${dotRoot}"

      # ------------------------------------------------------------
      # APPLICATION SUPPORT: MOVE FILES → DOTFILES
      # ------------------------------------------------------------
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        for item in "${asPath}"/*; do
          [ -e "$item" ] || continue
          name="$(basename "$item")"

          if [ ! -e "${dotRoot}/$name" ]; then
            mv "$item" "${dotRoot}/$name"
          else
            rm -rf "$item"
          fi
        done
      fi

      # Ensure Application Support directory exists
      mkdir -p "${asPath}"

      # ------------------------------------------------------------
      # APPLICATION SUPPORT: SYMLINK FILES BACK
      # ------------------------------------------------------------
      for item in "${dotRoot}"/*; do
        [ -e "$item" ] || continue
        name="$(basename "$item")"

        # Skip plist files
        case "$name" in
          *.plist) continue ;;
        esac

        ln -sfn "$item" "${asPath}/$name"
      done

      # ------------------------------------------------------------
      # PREFERENCES: MOVE PLIST → DOTFILES
      # ------------------------------------------------------------
      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPlist}" ]; then
        mv "${prefPlist}" "${dotPlist}"
      fi

      [ -f "${dotPlist}" ] || : > "${dotPlist}"

      # ------------------------------------------------------------
      # PREFERENCES: SYMLINK PLIST BACK
      # ------------------------------------------------------------
      ln -sfn "${dotPlist}" "${prefPlist}"
      
      echo "Done: Paste"
    '';
}
