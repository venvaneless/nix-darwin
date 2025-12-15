# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/appcleaner-symlinks.nix
#
# DARWIN: APPCLEANER USER-DATA
# ============================================================
# AppCleaner is a lightweight app uninstaller for macOS.
#
# Moves its Preferences plist into ven-dots and symlinks it back.
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/appcleaner
# ============================================================

{ config, lib, ... }:

let
  # PATHS
  # ------------------------------------------------------------
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder = "appcleaner";

  prefPlist = "${home}/Library/Preferences/net.freemacsoft.AppCleaner.plist";
  dotRoot   = "${dotsApp}/${appFolder}";
  dotPlist  = "${dotRoot}/net.freemacsoft.AppCleaner.plist";
in
{
  home.activation.appCleanerUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: AppCleaner"

      # DOTFILES: ENSURE ROOT EXISTS
      # ------------------------------------------------------------
      mkdir -p "${dotRoot}"

      # PREFERENCES: MIGRATE + SYMLINK
      # ------------------------------------------------------------
      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPlist}" ]; then
        echo "Moving plist → dotfiles"
        mv "${prefPlist}" "${dotPlist}"
      fi

      if [ ! -f "${dotPlist}" ]; then
        : > "${dotPlist}"
      fi

      ln -sfn "${dotPlist}" "${prefPlist}"

      echo "Done: AppCleaner"
    '';
}
