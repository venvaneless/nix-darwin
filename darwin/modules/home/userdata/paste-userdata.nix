# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/userdata/paste-userdata.nix
#
# DARWIN: PASTE USER-DATA (BACKUP)
# ============================================================
# Paste Direct user-data backup (mirror, no symlinks).
#
# Backup destination:
# - /Users/ven/ven-dots/user-data/apps/paste
#
# Runtime sources:
# - ~/Library/Application Support/com.wiheads.paste-direct/
# - ~/Library/Preferences/com.wiheads.paste-direct.plist
#
# Sync model:
# - Destination is a strict mirror of runtime state
# - New/changed files are copied
# - Removed files are removed from destination
#
# Safety model:
# - No symlinks
# - Deletions strictly scoped to Paste backup directory
# - Uses Nix-provided tools only
# - macOS-safe mtime handling
# - Never blocks Home Manager activation
# ============================================================

{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;

  dirRoot = "/Users/ven/ven-dots/user-data/apps";
  appSlug = "paste";
  dirDST  = "${dirRoot}/${appSlug}";

  asName = "com.wiheads.paste-direct";
  srcAS  = "${home}/Library/Application Support/${asName}";

  plistName = "com.wiheads.paste-direct.plist";
  srcPlist  = "${home}/Library/Preferences/${plistName}";
  dstPlist  = "${dirDST}/${plistName}";

  rsyncBin = "${pkgs.rsync}/bin/rsync";
in
{
  home.activation.pasteUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      APP="Paste"
      echo "[$APP] User-data backup starting… 🚀"

      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d 📁"
          mkdir -p "$d" || return 1
        fi
        return 0
      }

      file_mtime() {
        local f="$1"
        if [ -e "$f" ]; then
          date -r "$f" +%s 2>/dev/null || echo 0
        else
          echo 0
        fi
      }

      # ------------------------------------------------------------
      # --- DESTINATION ROOT ---
      # ------------------------------------------------------------
      if ! ensure_dir "${dirDST}"; then
        echo "[$APP] Failed to create backup root. Skipping ❌"
        exit 0
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT MIRROR ---
      # ------------------------------------------------------------
      if [ -d "${srcAS}" ]; then
        echo "[$APP] Mirroring Application Support: ${srcAS} → ${dirDST} 📦"
        if ${rsyncBin} -a --delete --itemize-changes "${srcAS}/" "${dirDST}/"; then
          echo "[$APP] Application Support mirror complete ✅"
        else
          echo "[$APP] rsync mirror failed (no abort) ⚠️"
        fi
      else
        echo "[$APP] Missing source directory. Skipping: ${srcAS} ✅"
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES PLIST (MTIME-AWARE) ---
      # ------------------------------------------------------------
      if [ -e "${srcPlist}" ]; then
        sm="$(file_mtime "${srcPlist}")"
        dm="$(file_mtime "${dstPlist}")"

        if [ "$sm" -gt "$dm" ]; then
          echo "[$APP] '${plistName}' is newer. Updating backup 📄"
          cp -p "${srcPlist}" "${dstPlist}" || echo "[$APP] Failed to copy plist ⚠️"
        else
          echo "[$APP] Plist up-to-date. Skipping ✅"
        fi
      else
        if [ -e "${dstPlist}" ]; then
          echo "[$APP] Runtime plist missing. Removing backup plist 🧹"
          rm -f "${dstPlist}" || echo "[$APP] Failed to remove backup plist ⚠️"
        else
          echo "[$APP] Runtime plist missing and no backup exists. Skipping ✅"
        fi
      fi

      echo "[$APP] User-data backup complete ✅"
    '';
}
