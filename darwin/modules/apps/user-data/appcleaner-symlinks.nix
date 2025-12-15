# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/appcleaner-symlinks.nix
#
# DARWIN: APPCLEANER USER-DATA
# ============================================================
# AppCleaner is a lightweight app uninstaller.
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/appcleaner
#
# Runtime locations:
#   ~/Library/Preferences/net.freemacsoft.AppCleaner.plist
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder = "appcleaner";

  plist    = "${home}/Library/Preferences/net.freemacsoft.AppCleaner.plist";
  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/net.freemacsoft.AppCleaner.plist";
in
{
  home.activation.appCleanerUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: AppCleaner"

      mkdir -p "${dotRoot}"

      [ -f "${plist}" ] && [ ! -f "${dotPlist}" ] && mv "${plist}" "${dotPlist}"
      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      ln -sfn "${dotPlist}" "${plist}"

      echo "Done: AppCleaner"
    '';
}
