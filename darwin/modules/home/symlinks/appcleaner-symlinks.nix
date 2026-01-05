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
#
# RULES
# -----
# - Only the plist is managed
# - No empty files are created
# - Existing data is reused
# - Safe to run repeatedly
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appSlug = "appcleaner";

  prefPlist = "${home}/Library/Preferences/net.freemacsoft.AppCleaner.plist";
  dotRoot   = "${dotsApp}/${appSlug}";
  dotPlist  = "${dotRoot}/net.freemacsoft.AppCleaner.plist";
in
{
  home.activation.appCleanerUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      APP="AppCleaner"

      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # SOURCE OF TRUTH
      # ------------------------------------------------------------
      mkdir -p "${dotRoot}"

      name="$(basename "${prefPlist}")"

      # ------------------------------------------------------------
      # PLIST MOVE + SYMLINK
      # ------------------------------------------------------------
      if [ -e "${prefPlist}" ] && [ ! -L "${prefPlist}" ]; then
        if [ ! -e "${dotPlist}" ]; then
          echo "[$APP] Moving '$name' → source-of-truth 📄"
          mv "${prefPlist}" "${dotPlist}"
        fi
      fi

      if [ -e "${dotPlist}" ] && [ ! -L "${prefPlist}" ]; then
        echo "[$APP] Symlinking '$name' back to Preferences 🔗"
        ln -s "${dotPlist}" "${prefPlist}"
      fi

      echo "[$APP] User-data sync complete ✅"
    '';
}
