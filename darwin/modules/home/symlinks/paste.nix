# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/paste-symlinks.nix
#
# DARWIN: PASTE USER-DATA (BACKUP)
# ============================================================
# Paste Direct user-data backup (mirror, no symlinks).
#
# Backup destination (repo):
# - /Users/ven/ven-dots/user-data/apps/paste
#
# What is backed up:
# - Application Support:
#   /Users/ven/Library/Application Support/com.wiheads.paste-direct/
#   → /Users/ven/ven-dots/user-data/apps/paste/
#
# - Preferences plist:
#   /Users/ven/Library/Preferences/com.wiheads.paste-direct.plist
#   → /Users/ven/ven-dots/user-data/apps/paste/com.wiheads.paste-direct.plist
#
# Sync model:
# - Destination is a strict mirror of the runtime source
# - New/changed files are copied over
# - Removed files are removed from the destination
# - Plist is copied only when newer; removed from destination if source is missing
#
# Safety model:
# - No symlinks
# - Never touches iCloud paths
# - Deletions (if any) are limited strictly to the Paste backup destination
# - Extensive logs for every action and skip reason
# - Never blocks Home Manager activation (failures are logged and do not abort activation)
# ============================================================

{ config, lib, ... }:

let
  # ------------------------------------------------------------
  # --- PATHS ---
  # ------------------------------------------------------------
  home = config.home.homeDirectory;

  # Source-of-truth root for all apps
  dirRoot = "/Users/ven/ven-dots/user-data/apps";

  # App slug (rules-compliant name)
  appSlug = "paste";

  # Backup destination root
  dirDST = "${dirRoot}/${appSlug}";

  # Runtime: Application Support directory
  asName = "com.wiheads.paste-direct";
  srcAS  = "${home}/Library/Application Support/${asName}";

  # Runtime: Preferences plist
  plistName = "com.wiheads.paste-direct.plist";
  srcPlist  = "${home}/Library/Preferences/${plistName}";

  # Backup: Preferences plist destination
  dstPlist  = "${dirDST}/${plistName}";
in
{
  home.activation.pasteUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="Paste"
      echo "[$APP] User-data backup starting… 🚀"

      # ------------------------------------------------------------
      # --- HELPERS: SAFE DIRECTORY CREATION ---
      # ------------------------------------------------------------
      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d 📁"
          if ! mkdir -p "$d"; then
            echo "[$APP] Failed to create directory: $d ❌"
            return 1
          fi
        fi
        return 0
      }

      # ------------------------------------------------------------
      # --- HELPERS: PATH CHECKS ---
      # ------------------------------------------------------------
      dir_has_content() {
        local d="$1"
        [ -d "$d" ] && [ -n "$(ls -A "$d" 2>/dev/null || true)" ]
      }

      # ------------------------------------------------------------
      # --- HELPERS: RSYNC MIRROR (WITH DELETE) ---
      # Mirrors src → dst.
      # Deletions are limited to the destination path only.
      # ------------------------------------------------------------
      rsync_mirror_dir() {
        local src="$1"
        local dst="$2"

        if [ ! -d "$src" ]; then
          echo "[$APP] Missing source directory. Skipping: $src ✅"
          return 0
        fi

        if ! dir_has_content "$src"; then
          echo "[$APP] Source directory exists but is empty. Proceeding with mirror (destination will be cleared) ⚠️"
        fi

        if ! ensure_dir "$dst"; then
          echo "[$APP] Destination directory could not be created. Skipping mirror ❌"
          return 0
        fi

        echo "[$APP] Mirroring Application Support: $src → $dst 📦"
        if rsync -a --delete --itemize-changes "$src"/ "$dst"/; then
          echo "[$APP] Application Support mirror complete ✅"
        else
          echo "[$APP] rsync mirror failed (no abort). Source: $src ⚠️"
          echo "[$APP] Destination left as-is (partial changes possible). Review output by re-running manually if needed 🧰"
        fi

        return 0
      }

      # ------------------------------------------------------------
      # --- HELPERS: PLIST COPY (MTIME-AWARE) ---
      # Copies plist only if source exists and is newer than destination.
      # If source is missing, destination is removed (mirror semantics).
      # ------------------------------------------------------------
      copy_plist_if_newer_or_remove() {
        local src="$1"
        local dst="$2"

        if [ ! -e "$src" ]; then
          if [ -e "$dst" ]; then
            echo "[$APP] Runtime plist missing; removing backup plist: $dst 🧹"
            if rm -f "$dst"; then
              echo "[$APP] Backup plist removed: $dst ✅"
            else
              echo "[$APP] Failed to remove backup plist: $dst ⚠️"
            fi
          else
            echo "[$APP] Runtime plist missing and no backup exists. Skipping ✅"
          fi
          return 0
        fi

        if ! ensure_dir "$(dirname "$dst")"; then
          echo "[$APP] Destination parent directory could not be created. Skipping plist copy ❌"
          return 0
        fi

        local sm dm
        sm="$(stat -f %m "$src" 2>/dev/null || echo 0)"

        if [ -e "$dst" ]; then
          dm="$(stat -f %m "$dst" 2>/dev/null || echo 0)"
        else
          dm="0"
        fi

        if [ "$sm" -le "$dm" ]; then
          echo "[$APP] Plist up-to-date. Skipping: $src ✅"
          return 0
        fi

        echo "[$APP] '${plistName}' is being copied to backup 📄"
        echo "[$APP] Copying: $src → $dst 📄"
        if cp -p "$src" "$dst"; then
          echo "[$APP] Plist backup updated: $dst ✅"
        else
          echo "[$APP] Failed to copy plist: $src ⚠️"
        fi

        return 0
      }

      # ------------------------------------------------------------
      # --- DESTINATION ROOT ---
      # ------------------------------------------------------------
      if ! ensure_dir "${dirDST}"; then
        echo "[$APP] Backup root could not be created. Skipping all actions ❌"
        echo "[$APP] User-data backup complete ✅"
        exit 0
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT MIRROR ---
      # /Users/ven/Library/Application Support/com.wiheads.paste-direct/ → /Users/ven/ven-dots/user-data/apps/paste/
      # ------------------------------------------------------------
      rsync_mirror_dir "${srcAS}" "${dirDST}"

      # ------------------------------------------------------------
      # --- PREFERENCES PLIST BACKUP ---
      # /Users/ven/Library/Preferences/com.wiheads.paste-direct.plist → /Users/ven/ven-dots/user-data/apps/paste/com.wiheads.paste-direct.plist
      # ------------------------------------------------------------
      copy_plist_if_newer_or_remove "${srcPlist}" "${dstPlist}"

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data backup complete ✅"
    '';
}
