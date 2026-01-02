# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/espanso-symlinks.nix
#
# DARWIN: ESPANSO USER-DATA
# ============================================================
# Espanso text expansion engine user-data management.
#
# Source of truth:
# - Application Support content lives in:  <dirSRC>/conf
# - Preferences plist lives in:            <dirSRC>/com.federicoterzi.espanso.plist
#
# Runtime paths (what Espanso still "sees"):
# - ~/Library/Application Support/espanso
# - ~/Library/Preferences/com.federicoterzi.espanso.plist
#
# Safety model:
# - If <dirSRC> is non-empty, migration is skipped
# - Exception: if runtime paths are NOT symlinks, they are repaired
# - Never creates duplicate profiles
# - Never overwrites existing dotfiles
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
  appSlug = "espanso";

  # App source-of-truth directories
  dirSRC  = "${dirRoot}/${appSlug}";
  dirConf = "${dirSRC}/conf";

  # Application Support runtime path
  asRealName = "espanso";
  asPath     = "${home}/Library/Application Support/${asRealName}";

  # Preferences runtime items
  prefItems = [
    "${home}/Library/Preferences/com.federicoterzi.espanso.plist"
  ];
in
{
  home.activation.espansoUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="Espanso"
      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # --- HELPERS: FILESYSTEM CHECKS ---
      # ------------------------------------------------------------
      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d 📁"
          mkdir -p "$d"
        fi
      }

      dir_is_empty() {
        local d="$1"
        [ -d "$d" ] || return 1
        [ -z "$(ls -A "$d" 2>/dev/null || true)" ]
      }

      unlink_if_symlink() {
        local p="$1"
        if [ -L "$p" ]; then
          echo "[$APP] Removing existing symlink: $p 🧹"
          unlink "$p"
        fi
      }

      # ------------------------------------------------------------
      # --- HELPERS: SAFE BACKUPS + MOVES ---
      # Non-empty directory or file → create timestamped backup
      # This ensures no existing data is destroyed and allows rollback
      # ------------------------------------------------------------
      backup_dest_if_needed() {
        local dst="$1"

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
          if [ -d "$dst" ] && dir_is_empty "$dst"; then
            echo "[$APP] Destination exists but empty. Removing empty dir: $dst 🧹"
            rmdir "$dst" || true
            return 0
          fi

          local ts
          ts="$(date +%Y%m%d-%H%M%S)"
          local backup
          backup="$dst.backup-$ts"

          echo "[$APP] Destination collision. Backing up: $dst → $backup 📦"
          mv "$dst" "$backup"
          echo "[$APP] Backup complete: $backup ✅"
        fi
      }

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
      # --- SOURCE OF TRUTH SETUP ---
      # ------------------------------------------------------------
      ensure_dir "${dirSRC}"
      ensure_dir "${dirConf}"

      allowMigrate="0"
      if dir_is_empty "${dirSRC}"; then
        echo "[$APP] Source-of-truth root is empty. Migration allowed ✅"
        allowMigrate="1"
      else
        echo "[$APP] Source-of-truth root is not empty. Migration skipped (repair still allowed) ⚠️"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT: MIGRATE OR REPAIR ---
      # ------------------------------------------------------------
      if [ -e "${asPath}" ]; then
        if [ -L "${asPath}" ]; then
          echo "[$APP] Application Support is a symlink. Verifying… 🔎"
          ensure_symlink "${asPath}" "${dirConf}" || true
        else
          # If runtime item is not a symlink, we repair it:
          # - If allowMigrate=1 -> normal migration
          # - If allowMigrate=0 -> repair mode (exception rule)
          if [ "$allowMigrate" = "1" ]; then
            echo "[$APP] Moving ${asRealName} profile → ${dirConf} 📦"
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
      # --- PREFERENCES: PLIST MOVE + SYMLINK ---
      # ------------------------------------------------------------
      for pref in ${lib.concatStringsSep " " prefItems}; do
        name="$(basename "$pref")"
        dst="${dirSRC}/$name"
      
        if [ -e "$pref" ]; then
          if [ -L "$pref" ]; then
            echo "[$APP] Preferences plist is a symlink. Verifying… 🔎"
            ensure_symlink "$pref" "$dst" || true
          else
            if [ ! -e "$dst" ]; then
              echo "[$APP] Moving '$name' → ${dirSRC} 📄"
              move_with_backup "$pref" "$dst"
            else
              echo "[$APP] Destination plist already exists. Skipping move ⚠️"
            fi
      
            ensure_symlink "$pref" "$dst" || true
            echo "[$APP] '$name' is being symlinked back to Preferences 🔗"
          fi
        else
          echo "[$APP] Preferences plist missing. Skipping ✅"
        fi
      done


      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
