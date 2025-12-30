# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/abetterfinderattributes-symlinks.nix
#
# DARWIN: A BETTER FINDER ATTRIBUTES USER-DATA
# ============================================================
# Bulk file attribute editor.
#
# Moves Application Support data into ven-dots as "conf" and symlinks it back.
# Moves Preferences items into ven-dots as "pref" and symlinks them back.
#
# Safety model:
# - Skips migration if source-of-truth root is non-empty
# - Still fixes broken symlinks even when skipping migration
# - Never creates fake preference files
# - Never links to iCloud; only checks iCloud paths as a preflight gate
# ============================================================

{ config, lib, ... }:

let
  # ------------------------------------------------------------
  # --- PATH DEFINITIONS ---
  # ------------------------------------------------------------
  home = config.home.homeDirectory;

  # Root directory for all app user-data
  dirRoot = "/Users/ven/ven-dots/user-data/apps";

  # App-specific source-of-truth root
  appName = "a_better_finder_attributes";
  dirSRC  = "${dirRoot}/${appName}";

  # Source-of-truth subdirectories
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
    "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/my-system/user-data/${appName}";
  iCloudConf = "${iCloudBase}/conf";
  iCloudPref = "${iCloudBase}/pref";
in
{
  home.activation.abfaUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- LOGGING SETUP ---
      # ------------------------------------------------------------
      APP="A Better Finder Attributes"
      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # --- HELPERS ---
      # ------------------------------------------------------------
      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d 📁"
          mkdir -p "$d"
        else
          echo "[$APP] Directory exists: $d ✅"
        fi
      }

      dir_is_empty() {
        local d="$1"
        [ -d "$d" ] || return 1
        [ -z "$(ls -A "$d" 2>/dev/null || true)" ]
      }

      safe_unlink_if_symlink() {
        local p="$1"
        if [ -L "$p" ]; then
          echo "[$APP] Removing existing symlink: $p 🧹"
          unlink "$p"
        fi
      }

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
          safe_unlink_if_symlink "$linkPath"
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

      move_with_backup_if_needed() {
        local src="$1"
        local dst="$2"

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
          if [ -d "$dst" ] && ! dir_is_empty "$dst"; then
            ts="$(date +%Y%m%d-%H%M%S)"
            backup="${dst}.backup-${ts}"
            echo "[$APP] Destination exists and non-empty. Backing up: $dst → $backup 📦"
            mv "$dst" "$backup"
            echo "[$APP] Backup complete: $backup ✅"
          elif [ -d "$dst" ]; then
            echo "[$APP] Destination exists but empty. Removing empty dir: $dst 🧹"
            rmdir "$dst" || true
          else
            ts="$(date +%Y%m%d-%H%M%S)"
            backup="${dst}.backup-${ts}"
            echo "[$APP] Destination exists (file). Backing up: $dst → $backup 📦"
            mv "$dst" "$backup"
            echo "[$APP] Backup complete: $backup ✅"
          fi
        fi

        echo "[$APP] Moving: $src → $dst 📦"
        mv "$src" "$dst"
        echo "[$APP] Move complete: $src → $dst ✅"
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
          elif [ -d "$p" ] && dir_is_empty "$p"; then
            echo "[$APP] iCloud gate: empty directory OK: $p ✅"
          else
            echo "[$APP] iCloud gate: path exists and is not empty. Blocking run: $p ⛔"
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
      # --- SOURCE OF TRUTH ROOT GUARD ---
      # ------------------------------------------------------------
      ensure_dir "${dirSRC}"

      allowMigrate="0"
      if dir_is_empty "${dirSRC}"; then
        echo "[$APP] Source-of-truth root is empty. Migration allowed ✅"
        allowMigrate="1"
      else
        echo "[$APP] Source-of-truth root is not empty. Migration skipped ⚠️"
      fi

      ensure_dir "${dirConf}"
      ensure_dir "${dirPref}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      if [ -e "${asPath}" ]; then
        if [ -L "${asPath}" ]; then
          ensure_symlink "${asPath}" "${dirConf}" || true
        elif [ "$allowMigrate" = "1" ]; then
          echo "[$APP] '${asRealName}' is being moved from Application Support → ${dirConf} 📦"
          move_with_backup_if_needed "${asPath}" "${dirConf}"
          ensure_symlink "${asPath}" "${dirConf}" || true
        else
          echo "[$APP] Application Support exists but migration skipped ⚠️"
        fi
      else
        echo "[$APP] No Application Support data found. Skipping section ✅"
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES ---
      # ------------------------------------------------------------
      for pref in ${lib.concatStringsSep " " prefItems}; do
        name="$(basename "$pref")"
        dst="${dirPref}/$name"

        if [ -e "$pref" ]; then
          if [ -L "$pref" ]; then
            ensure_symlink "$pref" "$dst" || true
          else
            if [ "$allowMigrate" = "1" ]; then
              move_with_backup_if_needed "$pref" "$dst"
            fi
            ensure_symlink "$pref" "$dst" || true
          fi
        else
          echo "[$APP] Preferences item missing. Skipping: $pref ✅"
        fi
      done

      echo "[$APP] User-data sync complete ✅"
    '';
}
