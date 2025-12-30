# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/abetterfinderattributes-symlinks.nix
#
# DARWIN: A BETTER FINDER ATTRIBUTES USER-DATA
# ============================================================
# Bulk file attribute editor.
#
# Source of truth:
# - Application Support content lives in:  <dirSRC>/conf
# - Preferences content lives in:          <dirSRC>/pref
#
# Runtime paths (what the app still "sees"):
# - ~/Library/Application Support/A Better Finder Attributes
# - ~/Library/Preferences/net.publicspace.abfa7.plist
# - ~/Library/Preferences/com.publicspace.abfa.plist
# - ~/Library/Preferences/net.publicspace.abfa7.binarycookies
#
# Safety model:
# - If <dirSRC> is non-empty, migration is skipped
# - Exception: if runtime paths are NOT symlinks, they are repaired
# - Never creates fake files
# - Never links to iCloud (iCloud paths are check-only gate)
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
  appSlug = "a_better_finder_attributes";

  # App source-of-truth directory
  dirSRC  = "${dirRoot}/${appSlug}";
  dirConf = "${dirSRC}/conf";
  dirPref = "${dirSRC}/pref";

  # Application Support runtime path
  asRealName = "A Better Finder Attributes";
  asPath     = "${home}/Library/Application Support/${asRealName}";

  # Preferences runtime items
  prefItems = [
    "${home}/Library/Preferences/net.publicspace.abfa7.plist"
    "${home}/Library/Preferences/com.publicspace.abfa.plist"
    "${home}/Library/Preferences/net.publicspace.abfa7.binarycookies"
  ];

  # ------------------------------------------------------------
  # --- ICLOUD PREFLIGHT (CHECK ONLY) ---
  # ------------------------------------------------------------
  iCloudBase =
    "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/my-system/user-data/${appSlug}";
  iCloudConf = "${iCloudBase}/conf";
  iCloudPref = "${iCloudBase}/pref";
in
{
  home.activation.abfaUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="A Better Finder Attributes"
      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # --- HELPERS: FILESYSTEM CHECKS ---
      # ------------------------------------------------------------

      # Directory creation (safe, idempotent)
      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d 📁"
          mkdir -p "$d"
        else
          echo "[$APP] Directory exists: $d ✅"
        fi
      }

      # Empty directory check (used for "skip if non-empty" rule)
      dir_is_empty() {
        local d="$1"
        [ -d "$d" ] || return 1
        [ -z "$(ls -A "$d" 2>/dev/null || true)" ]
      }

      # Remove only if path is a symlink (never delete real dirs/files)
      unlink_if_symlink() {
        local p="$1"
        if [ -L "$p" ]; then
          echo "[$APP] Removing existing symlink: $p 🧹"
          unlink "$p"
        fi
      }

      # ------------------------------------------------------------
      # --- HELPERS: SAFE BACKUPS + MOVES ---
      # ------------------------------------------------------------

      # Backup destination if it exists and is not a symlink.
      # This makes collisions safe without deleting anything.
      backup_dest_if_needed() {
        local dst="$1"

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
          # If it's a directory and empty -> remove empty dir (non-destructive)
          if [ -d "$dst" ] && dir_is_empty "$dst"; then
            echo "[$APP] Destination exists but empty. Removing empty dir: $dst 🧹"
            rmdir "$dst" || true
            return 0
          fi

          # Non-empty dir or file -> backup
          local ts
          ts="$(date +%Y%m%d-%H%M%S)"
          local backup
          backup="${dst}.backup-${ts}"

          echo "[$APP] Destination collision. Backing up: $dst → $backup 📦"
          mv "$dst" "$backup"
          echo "[$APP] Backup complete: $backup ✅"
        fi
      }

      # Safe move with backup handling.
      # NOTE: dst is a LOCAL variable here, so it can never be undefined.
      move_with_backup() {
        local src="$1"
        local dst="$2"

        backup_dest_if_needed "$dst"

        echo "[$APP] Moving: $src → $dst 📦"
        mv "$src" "$dst"
        echo "[$APP] Move complete: $src → $dst ✅"
      }

      # ------------------------------------------------------------
      # --- HELPERS: SYMLINK MANAGEMENT ---
      # ------------------------------------------------------------

      # Ensure symlink is present and points to the correct target.
      # - If symlink exists but points wrong -> replace it
      # - If real path exists (not symlink) -> do NOT delete automatically
      ensure_symlink() {
        local linkPath="$1"
        local targetPath="$2"

        if [ -L "$linkPath" ]; then
          local currentTarget
          currentTarget="$(readlink "$linkPath" || true)"

          if [ "$currentTarget" = "$targetPath" ]; then
            echo "[$APP] Symlink OK: $linkPath → $targetPath ✅"
            return 0
          fi

          echo "[$APP] Symlink wrong: $linkPath → $currentTarget (expected $targetPath) ⚠️"
          echo "[$APP] Fixing symlink: $linkPath → $targetPath 🔧"
          unlink_if_symlink "$linkPath"
          ln -s "$targetPath" "$linkPath"
          echo "[$APP] Symlink fixed: $linkPath → $targetPath ✅"
          return 0
        fi

        if [ -e "$linkPath" ]; then
          echo "[$APP] Not a symlink at: $linkPath (will not delete automatically) ⚠️"
          return 1
        fi

        echo "[$APP] Creating symlink: $linkPath → $targetPath 🔗"
        ln -s "$targetPath" "$linkPath"
        echo "[$APP] Symlink created: $linkPath → $targetPath ✅"
      }

      # ------------------------------------------------------------
      # --- ICLOUD PREFLIGHT GATE (CHECK ONLY) ---
      # ------------------------------------------------------------
      iCloudGateOk="1"

      for p in "${iCloudConf}" "${iCloudPref}"; do
        if [ -e "$p" ]; then
          if [ -L "$p" ]; then
            echo "[$APP] iCloud gate: path is a symlink. Blocking run: $p ⛔"
            iCloudGateOk="0"
          elif [ -d "$p" ]; then
            if dir_is_empty "$p"; then
              echo "[$APP] iCloud gate: empty directory OK (not symlink): $p ✅"
            else
              echo "[$APP] iCloud gate: directory not empty. Blocking run: $p ⛔"
              iCloudGateOk="0"
            fi
          else
            echo "[$APP] iCloud gate: path exists but is not a directory. Blocking run: $p ⛔"
            iCloudGateOk="0"
          fi
        else
          echo "[$APP] iCloud gate: path does not exist (OK): $p ✅"
        fi
      done

      if [ "$iCloudGateOk" != "1" ]; then
        echo "[$APP] User-data sync skipped due to iCloud gate failure ✅"
        exit 0
      fi

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH SETUP ---
      # ------------------------------------------------------------
      # Root exists
      ensure_dir "${dirSRC}"

      # "Empty root means migration allowed" gate
      allowMigrate="0"
      if dir_is_empty "${dirSRC}"; then
        echo "[$APP] Source-of-truth root is empty. Migration allowed ✅"
        allowMigrate="1"
      else
        echo "[$APP] Source-of-truth root is not empty. Migration skipped (repair still allowed) ⚠️"
      fi

      # Subdirs exist
      ensure_dir "${dirConf}"
      ensure_dir "${dirPref}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT: MIGRATE OR REPAIR ---
      # ------------------------------------------------------------
      if [ -e "${asPath}" ]; then
        if [ -L "${asPath}" ]; then
          echo "[$APP] Application Support is a symlink. Verifying… 🔎"
          ensure_symlink "${asPath}" "${dirConf}" || true
        else
          # If not symlink, we repair (move into conf + link back)
          # - If allowMigrate=1 -> normal migration
          # - If allowMigrate=0 -> repair mode (your exception rule)
          if [ "$allowMigrate" = "1" ]; then
            echo "[$APP] '${asRealName}' is being moved from Application Support → ${dirConf} 📦"
          else
            echo "[$APP] Application Support is not a symlink. Repairing into ${dirConf} 🔧"
          fi

          move_with_backup "${asPath}" "${dirConf}"

          echo "[$APP] '${asRealName}' is being symlinked back to Application Support 🔗"
          ensure_symlink "${asPath}" "${dirConf}" || {
            echo "[$APP] ERROR: Could not create symlink at Application Support ⛔"
          }
        fi
      else
        echo "[$APP] No Application Support data found. Skipping Application Support ✅"
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES: MIGRATE OR REPAIR ---
      # ------------------------------------------------------------
      for pref in ${lib.concatStringsSep " " prefItems}; do
        name="$(basename "$pref")"
        dst="${dirPref}/$name"

        if [ -e "$pref" ]; then
          if [ -L "$pref" ]; then
            echo "[$APP] Preferences item is a symlink. Verifying: $pref 🔎"
            ensure_symlink "$pref" "$dst" || true
          else
            # If runtime item is not a symlink, we always repair it:
            # - move into pref (with backup collision handling)
            # - link back to runtime path
            echo "[$APP] '$name' is NOT a symlink. Moving into ${dirPref} 📄"
            move_with_backup "$pref" "$dst"

            echo "[$APP] '$name' is being symlinked back to Preferences 🔗"
            ensure_symlink "$pref" "$dst" || {
              echo "[$APP] ERROR: Could not create symlink in Preferences ⛔"
            }
          fi
        else
          echo "[$APP] Preferences item missing. Skipping: $pref ✅"
        fi
      done

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
