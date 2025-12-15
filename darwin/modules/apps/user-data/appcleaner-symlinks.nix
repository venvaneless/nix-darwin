# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/appcleaner-symlinks.nix
#
# DARWIN: APPCLEANER USER-DATA
# ============================================================
# AppCleaner is a lightweight app uninstaller.
#
# SOURCE OF TRUTH:
#   /Users/ven/ven-dots/user-data/apps/appcleaner
#
# RUNTIME LOCATION:
#   ~/Library/Preferences/net.freemacsoft.AppCleaner.plist
# ============================================================

{ config, lib, ... }:

let
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
      echo "[AppCleaner] Syncing user-data"

      mkdir -p "${dotRoot}"

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPlist}" ]; then
        mv "${prefPlist}" "${dotPlist}"
      fi

      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      ln -sfn "${dotPlist}" "${prefPlist}"
      
      echo "AppCleaner: Done: User-data sync complete"
    '';
}
