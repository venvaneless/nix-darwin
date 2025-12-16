# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/espanso-symlinks.nix
#
# DARWIN: ESPANSO USER-DATA
# ============================================================
# Espanso is a system-wide text expansion and productivity tool.
#
# SOURCE OF TRUTH:
#   /Users/ven/ven-dots/user-data/apps/espanso
#
# RUNTIME LOCATIONS:
#   ~/Library/Application Support/espanso
#   ~/Library/Preferences/com.federicoterzi.espanso.plist
#
# RESPONSIBILITIES:
#   - Move Application Support directory into dotfiles
#   - Symlink it back under the original name
#   - Move preferences plist into dotfiles
#   - Symlink plist back
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder  = "espanso";
  asRealName = "espanso";

  asPath    = "${home}/Library/Application Support/${asRealName}";
  prefPlist = "${home}/Library/Preferences/com.federicoterzi.espanso.plist";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.federicoterzi.espanso.plist";
in
{
  home.activation.espansoUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[Espanso] Syncing user-data"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH ---
      # ------------------------------------------------------------
      mkdir -p "${dotsApp}"

      if [ ! -d "${dotRoot}" ]; then
        echo "[Espanso] ${dotRoot} doesn't exist for Espanso yet. Creating. 📁"
        mkdir -p "${dotRoot}"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        if [ -e "${dotRoot}" ] && [ "$(ls -A "${dotRoot}" 2>/dev/null || true)" != "" ]; then
          echo "[Espanso] WARNING: '${asRealName}' exists in Application Support and '${dotRoot}' is not empty. Skipping move. ⚠️"
        else
          echo "[Espanso] '${asRealName}' is being moved from Application Support to ${dotRoot} 📦"
          rm -rf "${dotRoot}" 2>/dev/null || true
          mv "${asPath}" "${dotRoot}"
          echo "[Espanso] '${asRealName}' has been successfully moved from ${asPath} to ${dotRoot} ✅"
        fi
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"
      echo "[Espanso] '${asRealName}' is being symlinked back to ${asPath} 🔗"

      # ------------------------------------------------------------
      # --- PREFERENCES ---
      # ------------------------------------------------------------
      name="$(basename "${prefPlist}")"

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -e "${dotPlist}" ]; then
        echo "[Espanso] '$name' is being moved from Preferences to ${dotRoot} 📄"
        mv "${prefPlist}" "${dotPlist}"
        echo "[Espanso] '$name' has been successfully moved from ${prefPlist} to ${dotPlist} ✅"
      fi

      [ -e "${dotPlist}" ] || : > "${dotPlist}"

      ln -sfn "${dotPlist}" "${prefPlist}"
      echo "[Espanso] '$name' is being symlinked back to ${prefPlist} 🔗"

      echo "Espanso: User-data sync complete ✅"
    '';
}
