# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/userdata/yate-userdata.nix
#
# DARWIN: YATE USER-DATA (BACKUP)
# ============================================================
# Yate user-data backup (mirror, no symlinks).
#
# Backup destination:
# - /Users/ven/ven-dots/user-data/apps/yate
#
# Runtime sources:
# - ~/Library/Application Support/Yate/
# - ~/Library/Preferences/com.2manyrobots.Yate.plist
#
# Sync model:
# - Destination is a strict mirror of runtime state
# - New / modified files are copied
# - Removed files are removed from destination
#
# Safety model:
# - NO symlinks
# - Runtime paths remain authoritative
# - Deletions strictly scoped to Yate backup directory
# - Uses Nix-provided tools only
# - macOS-safe mtime handling
# - Never blocks Home Manager activation
# ============================================================

{ config, lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # --- PATHS ---
  # ------------------------------------------------------------
  home = config.home.homeDirectory;

  # Backup root
  dirRoot = "/Users/ven/ven-dots/user-data/apps";
  appSlug = "yate";
  dirDST  = "${dirRoot}/${appSlug}";

  # Runtime sources
  srcAS    = "${home}/Library/Application Support/Yate";
  plistName = "com.2manyrobots.Yate.plist";
  srcPlist  = "${home}/Library/Preferences/${plistName}";
  dstPlist  = "${dirDST}/${plistName}";

  # Nix-provided rsync
  rsyncBin = "${pkgs.rsync}/bin/rsync";
in
{
  home.activation.yateUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      APP="Yate"
      echo "[$APP] User-data backup starting… 🚀"

      # ------------------------------------------------------------
      # --- HELPERS ---
      # ------------------------------------------------------------
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
      # ~/Library/Application Support/Yate → <dirDST>/
      # ------------------------------------------------------------
      if [ -d "${srcAS}" ]; then
        echo "[$APP] Mirroring Application Support: ${srcAS} → ${dirDST} 📦"

        if ${rsyncBin} -a --delete --itemize-changes "${srcAS}/" "${dirDST}/"; then
          echo "[$APP] Application Support mirror complete ✅"
        else
          echo "[$APP] rsync mirror failed (no abort) ⚠️"
        fi
      else
        echo "[$APP] Missing Application Support directory. Skipping: ${srcAS} ✅"
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
          echo "[$APP] Preferences plist up-to-date. Skipping ✅"
        fi
      else
        if [ -e "${dstPlist}" ]; then
          echo "[$APP] Runtime plist missing. Removing backup plist 🧹"
          rm -f "${dstPlist}" || echo "[$APP] Failed to remove backup plist ⚠️"
        else
          echo "[$APP] Runtime plist missing and no backup exists. Skipping ✅"
        fi
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data backup complete ✅"
    '';
}
