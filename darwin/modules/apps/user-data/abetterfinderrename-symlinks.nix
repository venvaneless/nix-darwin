# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/abetterfinderrename-symlinks.nix
#
# DARWIN: A BETTER FINDER RENAME USER-DATA
# ============================================================
# Bulk file renaming utility.
#
# SOURCE OF TRUTH:
#   /Users/ven/ven-dots/user-data/apps/a_better_finder_rename
#
# RUNTIME LOCATIONS:
#   ~/Library/Application Support/A Better Finder Rename 12
#   ~/Library/Preferences/net.publicspace.abfr12.plist
#   ~/Library/Preferences/ABFR Registration
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder  = "a_better_finder_rename";
  asRealName = "A Better Finder Rename 12";

  asPath = "${home}/Library/Application Support/${asRealName}";

  plist = "${home}/Library/Preferences/net.publicspace.abfr12.plist";
  reg   = "${home}/Library/Preferences/ABFR Registration";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPrefs = "${dotRoot}/Preferences";
in
{
  home.activation.abfrUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[ABFR] Syncing user-data"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH ---
      # ------------------------------------------------------------
      mkdir -p "${dotsApp}"

      if [ ! -d "${dotRoot}" ]; then
        echo "[ABFR] ${dotRoot} doesn't exist for A Better Finder Rename yet. Creating. 📁"
        mkdir -p "${dotRoot}"
      fi

      if [ ! -d "${dotPrefs}" ]; then
        echo "[ABFR] Preferences folder doesn't exist for A Better Finder Rename yet. Creating. 📁"
        mkdir -p "${dotPrefs}"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        if [ -e "${dotRoot}" ] && [ "$(ls -A "${dotRoot}" 2>/dev/null || true)" != "" ]; then
          echo "[ABFR] WARNING: '${asRealName}' exists in Application Support and '${dotRoot}' is not empty. Skipping move. ⚠️"
        else
          echo "[ABFR] '${asRealName}' is being moved from Application Support to ${dotRoot} 📦"
          rm -rf "${dotRoot}" 2>/dev/null || true
          mv "${asPath}" "${dotRoot}"
          echo "[ABFR] '${asRealName}' has been successfully moved from ${asPath} to ${dotRoot} ✅"
        fi
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"
      echo "[ABFR] '${asRealName}' is being symlinked back to ${asPath} 🔗"

      # ------------------------------------------------------------
      # --- PREFERENCES ---
      # ------------------------------------------------------------
      for pref in "${plist}" "${reg}"; do
        name="$(basename "$pref")"

        if [ -f "$pref" ] && [ ! -L "$pref" ] && [ ! -e "${dotPrefs}/$name" ]; then
          echo "[ABFR] '$name' is being moved from Preferences to ${dotPrefs} 📄"
          mv "$pref" "${dotPrefs}/$name"
          echo "[ABFR] '$name' has been successfully moved from $pref to ${dotPrefs}/$name ✅"
        fi

        if [ ! -e "${dotPrefs}/$name" ]; then
          : > "${dotPrefs}/$name"
        fi

        ln -sfn "${dotPrefs}/$name" "$pref"
        echo "[ABFR] '$name' is being symlinked back to $pref 🔗"
      done

      echo "ABFR: User-data sync complete ✅"
    '';
}
