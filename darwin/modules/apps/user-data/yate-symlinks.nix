# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/yate-symlinks.nix
#
# DARWIN: YATE USER-DATA
# ============================================================
# Yate is an advanced audio metadata editor.
#
# SOURCE OF TRUTH:
#   /Users/ven/ven-dots/user-data/apps/yate
#
# RUNTIME LOCATIONS:
#   ~/Library/Application Support/Yate
#   ~/Library/Preferences/com.2manyrobots.Yate.plist
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder  = "yate";
  asRealName = "Yate";

  asPath    = "${home}/Library/Application Support/${asRealName}";
  prefPlist = "${home}/Library/Preferences/com.2manyrobots.Yate.plist";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.2manyrobots.Yate.plist";
in
{
  home.activation.yateUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[Yate] Syncing user-data"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH ---
      # ------------------------------------------------------------
      mkdir -p "${dotsApp}"

      if [ ! -d "${dotRoot}" ]; then
        echo "[Yate] ${dotRoot} doesn't exist for Yate yet. Creating. 📁"
        mkdir -p "${dotRoot}"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        if [ -e "${dotRoot}" ] && [ "$(ls -A "${dotRoot}" 2>/dev/null || true)" != "" ]; then
          echo "[Yate] WARNING: '${asRealName}' exists in Application Support and '${dotRoot}' is not empty. Skipping move. ⚠️"
        else
          echo "[Yate] '${asRealName}' is being moved from Application Support to ${dotRoot} 📦"
          rm -rf "${dotRoot}" 2>/dev/null || true
          mv "${asPath}" "${dotRoot}"
          echo "[Yate] '${asRealName}' has been successfully moved from ${asPath} to ${dotRoot} ✅"
        fi
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"
      echo "[Yate] '${asRealName}' is being symlinked back to ${asPath} 🔗"

      # ------------------------------------------------------------
      # --- PREFERENCES ---
      # ------------------------------------------------------------
      name="$(basename "${prefPlist}")"

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -e "${dotPlist}" ]; then
        echo "[Yate] '$name' is being moved from Preferences to ${dotRoot} 📄"
        mv "${prefPlist}" "${dotPlist}"
        echo "[Yate] '$name' has been successfully moved from ${prefPlist} to ${dotPlist} ✅"
      fi

      [ -e "${dotPlist}" ] || : > "${dotPlist}"

      ln -sfn "${dotPlist}" "${prefPlist}"
      echo "[Yate] '$name' is being symlinked back to ${prefPlist} 🔗"

      echo "Yate: User-data sync complete ✅"
    '';
}
