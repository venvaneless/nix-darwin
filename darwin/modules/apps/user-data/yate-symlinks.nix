# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/yate-symlinks.nix
#
# DARWIN: YATE USER-DATA BACKUP
# ============================================================
# Yate is an advanced audio metadata editor.
#
# This module keeps a non-destructive, up-to-date backup of
# Yate user data and preferences inside ven-dots.
#
# NO FILES ARE MOVED OR SYMLINKED.
# Runtime locations remain authoritative.
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder  = "yate";

  asPath    = "${home}/Library/Application Support/Yate";
  prefPlist = "${home}/Library/Preferences/com.2manyrobots.Yate.plist";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.2manyrobots.Yate.plist";
in
{
  home.activation.yateUserDataBackup =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[Yate] Syncing user-data (backup-only)"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH (BACKUP TARGET) ---
      # ------------------------------------------------------------
      mkdir -p "${dotsApp}"

      if [ ! -d "${dotRoot}" ]; then
        echo "[Yate] ${dotRoot} doesn't exist for Yate yet. Creating. 📁"
        mkdir -p "${dotRoot}"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT BACKUP ---
      # ------------------------------------------------------------
      if [ -d "${asPath}" ]; then
        echo "[Yate] Backing up Application Support data to ${dotRoot} 📦"
        rm -rf "${dotRoot:?}"/*
        cp -a "${asPath}/." "${dotRoot}/"
        echo "[Yate] Application Support data backed up successfully ✅"
      else
        echo "[Yate] Application Support directory not found. Skipping. ⚠️"
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES BACKUP ---
      # ------------------------------------------------------------
      if [ -f "${prefPlist}" ]; then
        echo "[Yate] Backing up preferences plist to ${dotRoot} 📄"
        cp -a "${prefPlist}" "${dotPlist}"
        echo "[Yate] Preferences plist backed up successfully ✅"
      else
        echo "[Yate] Preferences plist not found. Skipping. ⚠️"
      fi

      echo "Yate: User-data backup complete ✅"
    '';
}
