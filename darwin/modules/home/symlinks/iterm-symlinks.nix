# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/iterm-symlinks.nix
#
# DARWIN: ITERM USER-DATA
# ============================================================
# iTerm2 terminal emulator user-data management.
#
# Source of truth:
# - Application Support content lives in:  <dirSRC>/conf
# - Preferences plists live in:            <dirSRC>/pref
#
# Runtime paths (what iTerm still "sees"):
# - ~/Library/Application Support/iTerm2
# - ~/Library/Preferences/com.googlecode.iterm2.plist
# - ~/Library/Preferences/com.googlecode.iterm2.private.plist
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
  appSlug = "iterm";

  # App source-of-truth directories
  dirSRC  = "${dirRoot}/${appSlug}";
  dirConf = "${dirSRC}/conf";
  dirPref = "${dirSRC}/pref";

  # Application Support runtime path
  asRealName = "iTerm2";
  asPath     = "${home}/Library/Application Support/${asRealName}";

  # Preferences runtime items
  prefItems = [
    "${home}/Library/Preferences/com.googlecode.iterm2.plist"
    "${home}/Library/Preferences/com.googlecode.iterm2.private.plist"
  ];
in
{
  home.activation.itermUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="iTerm2"
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
      ensure_dir "${dirConf}"
      ensure_dir "${dirPref}"

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
      # --- PREFERENCES: PLISTS MOVE + SYMLINK ---
      # ------------------------------------------------------------
      for pref in ${lib.concatStringsSep " " prefItems}; do
        name="$(basename "$pref")"
        dst="${dirPref}/$name"

        if [ -e "$pref" ]; then
          if [ -L "$pref" ]; then
            echo "[$APP] Preferences item is a symlink. Verifying: $pref 🔎"
          else
            if [ ! -e "$dst" ]; then
              echo "[$APP] Moving '$name' → ${dirPref} 📄"
              move_with_backup "$pref" "$dst"
            fi
          fi
        fi

        ln -sfn "$dst" "$pref"
        echo "[$APP] '$name' is being symlinked back to Preferences 🔗"
      done

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
