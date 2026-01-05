# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/appcleaner-symlinks.nix
#
# DARWIN: APPCLEANER USER-DATA
# ============================================================
# AppCleaner is a lightweight app uninstaller.
#
# SOURCE OF TRUTH
# ----------------
#   /Users/ven/ven-dots/user-data/apps/net.freemacsoft.AppCleaner.plist
#
# RUNTIME LOCATION
# ----------------
#   ~/Library/Preferences/net.freemacsoft.AppCleaner.plist
#
# RULES
# -----
# - Only the plist is managed
# - Plist is MOVED once, then SYMLINKED
# - No empty files are created
# - Safe to run repeatedly
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  dotsRoot = "/Users/ven/ven-dots/user-data/apps";

  prefPlist = "${home}/Library/Preferences/net.freemacsoft.AppCleaner.plist";
  dotPlist  = "${dotsRoot}/net.freemacsoft.AppCleaner.plist";
in
{
  home.activation.appCleanerUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="AppCleaner"
      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH ---
      # ------------------------------------------------------------
      mkdir -p "${dotsRoot}"

      name="$(basename "${prefPlist}")"

      # ------------------------------------------------------------
      # --- PLIST MOVE + SYMLINK ---
      # ------------------------------------------------------------
      if [ -e "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -e "${dotPlist}" ]; then
        echo "[$APP] Moving '$name' → source-of-truth 📄"
        mv "${prefPlist}" "${dotPlist}"
      fi

      if [ -e "${dotPlist}" ] && [ ! -L "${prefPlist}" ]; then
        echo "[$APP] Symlinking '$name' back to Preferences 🔗"
        ln -s "${dotPlist}" "${prefPlist}"
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
