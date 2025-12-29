# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/appcleaner-symlinks.nix
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

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH ---
      # ------------------------------------------------------------
      mkdir -p "${dotsApp}"

      if [ ! -d "${dotRoot}" ]; then
        echo "[AppCleaner] ${dotRoot} doesn't exist for AppCleaner yet. Creating. 📁"
        mkdir -p "${dotRoot}"
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES ---
      # ------------------------------------------------------------
      name="$(basename "${prefPlist}")"

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -e "${dotPlist}" ]; then
        echo "[AppCleaner] '$name' is being moved from Preferences to ${dotRoot} 📄"
        mv "${prefPlist}" "${dotPlist}"
        echo "[AppCleaner] '$name' has been successfully moved from ${prefPlist} to ${dotPlist} ✅"
      fi

      [ -e "${dotPlist}" ] || : > "${dotPlist}"

      ln -sfn "${dotPlist}" "${prefPlist}"
      echo "[AppCleaner] '$name' is being symlinked back to ${prefPlist} 🔗"

      echo "AppCleaner: User-data sync complete ✅"
    '';
}
