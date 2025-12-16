# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/paste-symlinks.nix
#
# DARWIN: PASTE USER-DATA BACKUP
# ============================================================
# Paste is a clipboard manager for macOS.
#
# This module keeps a non-destructive, up-to-date backup of
# Paste user data and preferences inside ven-dots.
#
# NO FILES ARE MOVED OR SYMLINKED.
# Runtime locations remain authoritative.
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder = "paste";

  asPath    = "${home}/Library/Application Support/com.wiheads.paste-direct";
  prefPlist = "${home}/Library/Preferences/com.wiheads.paste-direct.plist";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.wiheads.paste-direct.plist";
in
{
  home.activation.pasteUserDataBackup =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[Paste] Syncing user-data (backup-only)"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH (BACKUP TARGET) ---
      # ------------------------------------------------------------
      mkdir -p "${dotsApp}"

      if [ ! -d "${dotRoot}" ]; then
        echo "[Paste] ${dotRoot} doesn't exist for Paste yet. Creating. 📁"
        mkdir -p "${dotRoot}"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT BACKUP ---
      # ------------------------------------------------------------
      if [ -d "${asPath}" ]; then
        echo "[Paste] Backing up Application Support data to ${dotRoot} 📦"
        rm -rf "${dotRoot:?}"/*
        cp -a "${asPath}/." "${dotRoot}/"
        echo "[Paste] Application Support data backed up successfully ✅"
      else
        echo "[Paste] Application Support directory not found. Skipping. ⚠️"
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES BACKUP ---
      # ------------------------------------------------------------
      if [ -f "${prefPlist}" ]; then
        echo "[Paste] Backing up preferences plist to ${dotRoot} 📄"
        cp -a "${prefPlist}" "${dotPlist}"
        echo "[Paste] '$name' is being symlinked back to ${prefPlist} 🔗"
      else
        echo "[Paste] '$name' is missing in source of truth. Skipping symlink. ⚠️"
      fi

      echo "Paste: User-data backup complete ✅"
    '';
}
