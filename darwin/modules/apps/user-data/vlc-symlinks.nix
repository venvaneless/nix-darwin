# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/vlc-symlinks.nix
#
# DARWIN: VLC USER-DATA
# ============================================================
# VLC is a media player for macOS.
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/vlc
#
# Runtime locations:
#   ~/Library/Application Support/org.videolan.vlc/
#     - vlcrc
#     - ml.xspf
#
#   ~/Library/Preferences/org.videolan.vlc.plist
#
# Responsibilities:
#   - Ensure dotfiles folder exists
#   - Move VLC files from Application Support into dotfiles
#   - Move VLC plist from Preferences into dotfiles
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
  # VLC IDENTIFIERS
  # ------------------------------------------------------------
  appFolder = "vlc";

  # ------------------------------------------------------------
  # VLC RUNTIME PATHS
  # ------------------------------------------------------------
  asDirName = "org.videolan.vlc";
  asPath    = "${home}/Library/Application Support/${asDirName}";

  prefPlist = "${home}/Library/Preferences/org.videolan.vlc.plist";

  # ------------------------------------------------------------
  # DOTFILES PATHS (SOURCE OF TRUTH)
  # ------------------------------------------------------------
  dotRoot   = "${dotsApp}/${appFolder}";
  dotPlist  = "${dotRoot}/org.videolan.vlc.plist";
in
{
  home.activation.vlcUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: VLC"

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

      echo "VLC user-data sync complete."
    '';
}
