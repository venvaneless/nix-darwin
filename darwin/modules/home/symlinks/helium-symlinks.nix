# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/helium-symlinks.nix
#
# DARWIN: CHROMIUM USER-DATA
# ============================================================
# Chromium browser user-data management.
#
# Source of truth:
# - Application Support content lives in:  <dirSRC>/conf
# - Preferences plist lives in:            <dirSRC>/org.chromium.Chromium.plist
#
# Runtime paths (what Chromium still "sees"):
# - ~/Library/Application Support/Chromium
# - ~/Library/Preferences/org.chromium.Chromium.plist
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
  
  # App name
  asRealName = "Helium";
  
  # App slug (rules-compliant name)
  appSlug = "helium";

  # App source-of-truth directory
  dirSRC  = "${dirRoot}/${appSlug}";
  dirConf = "${dirSRC}/conf";

  # Application Support runtime path
  asPath     = "${home}/Library/Application Support/${asRealName}";

  # Preferences runtime items
  prefPlist = "${home}/Library/Preferences/org.chromium.Chromium.plist";
  dotPlist  = "${dirSRC}/net.imput.helium.plist";
in
{
  home.activation.chromiumUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="${asRealName}"
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
            rmdir "$dst" || true
            return 0
          fi

          local ts
          ts="$(date +%Y%m%d-%H%M%S)"
          local backup
          backup="$dst.backup-$ts"

          echo "[$APP] Destination collision. Backing up: $dst → $backup 📦"
          mv "$dst" "$backup"
        fi
      }

      move_with_backup() {
        local src="$1"
        local dst="$2"

        backup_dest_if_needed "$dst"
        echo "[$APP] Moving: $src → $dst 📦"
        mv "$src" "$dst"
      }

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH SETUP ---
      # ------------------------------------------------------------
      ensure_dir "${dirSRC}"

      allowMigrate="0"
      if dir_is_empty "${dirSRC}"; then
        echo "[$APP] Source-of-truth root is empty. Migration allowed ✅"
        allowMigrate="1"
      else
        echo "[$APP] Source-of-truth root is not empty. Migration skipped (repair still allowed) ⚠️"
      fi

      ensure_dir "${dirConf}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT: MIGRATE OR REPAIR ---
      # ------------------------------------------------------------
      if [ -e "${asPath}" ]; then
        if [ -L "${asPath}" ]; then
          echo "[$APP] Application Support is a symlink. Verifying… 🔎"
        else
          if [ "$allowMigrate" = "1" ]; then
          echo "[$APP] Moving ${asRealName} profile → ${dirConf} 📦"
            move_with_backup "${asPath}" "${dirConf}"
          else
            echo "[$APP] Application Support exists but migration skipped ⚠️"
          fi
        fi
      fi

      unlink_if_symlink "${asPath}"
      ln -sfn "${dirConf}" "${asPath}"
      echo "[$APP] Application Support symlinked → ${dirConf} 🔗"

      # ------------------------------------------------------------
      # --- PREFERENCES: PLIST MOVE + SYMLINK ---
      # ------------------------------------------------------------
      if [ -e "${prefPlist}" ]; then
        if [ -L "${prefPlist}" ]; then
          echo "[$APP] Preferences plist already symlinked. Verifying… 🔎"
        else
          if [ ! -e "${dotPlist}" ]; then
            echo "[$APP] Moving plist → ${dotPlist} 📄"
            move_with_backup "${prefPlist}" "${dotPlist}"
          fi
        fi
      fi

      ln -sfn "${dotPlist}" "${prefPlist}"
      echo "[$APP] Preferences plist symlinked → ${dotPlist} 🔗"

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
