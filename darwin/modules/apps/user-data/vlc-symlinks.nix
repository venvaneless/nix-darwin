# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/vlc-symlinks.nix
#
# VLC USER-DATA
# ============================================================
# VLC media player for macOS.
#
# VLC stores all user state in:
# - ~/Library/Preferences/org.videolan.vlc/ (directory)
# - ~/Library/Preferences/org.videolan.vlc.plist
#
# This module migrates both into ven-dots and symlinks them back.
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
  prefDir   = "${home}/Library/Preferences/org.videolan.vlc";
  prefPlist = "${home}/Library/Preferences/org.videolan.vlc.plist";

  # ------------------------------------------------------------
  # DOTFILES PATHS
  # ------------------------------------------------------------
  dotRoot     = "${dotsApp}/${appFolder}";
  dotPrefDir  = "${dotRoot}/org.videolan.vlc";
  dotPrefPlist = "${dotRoot}/org.videolan.vlc.plist";
in
{
  home.activation.vlcUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: VLC"

      # ------------------------------------------------------------
      # DOTFILES ROOT
      # ------------------------------------------------------------
      mkdir -p "${dotRoot}"

      # ------------------------------------------------------------
      # PREFERENCES DIRECTORY
      # ------------------------------------------------------------
      if [ -d "${prefDir}" ] && [ ! -L "${prefDir}" ]; then
        echo "Migrating VLC preferences directory"
        mv "${prefDir}" "${dotPrefDir}"
      fi

      rm -rf "${prefDir}" 2>/dev/null || true
      ln -sfn "${dotPrefDir}" "${prefDir}"

      # ------------------------------------------------------------
      # PREFERENCES PLIST
      # ------------------------------------------------------------
      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPrefPlist}" ]; then
        echo "Migrating VLC plist"
        mv "${prefPlist}" "${dotPrefPlist}"
      fi

      [ -f "${dotPrefPlist}" ] || : > "${dotPrefPlist}"
      ln -sfn "${dotPrefPlist}" "${prefPlist}"

      echo "Done: VLC"
    '';
}
