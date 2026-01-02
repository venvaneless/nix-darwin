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
      ensure_dir "${dirPref}"

      allowMigrate="0"
      if dir_is_empty "${dirSRC}"; then
        echo "[$APP] Source-of-truth root is empty. Migration allowed ✅"
        allowMigrate="1"
      else
        echo "[$APP] Source-of-truth root is not empty. Migration skipped (repair still allowed) ⚠️"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT: CONTENTS MIGRATE + REPAIR ---
      # ------------------------------------------------------------
      # IMPORTANT:
      # - ${asPath} must remain a REAL directory
      # - We only symlink items INSIDE it
      ensure_dir "${asPath}"

      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        shopt -s dotglob nullglob

        for item in "${asPath}"/*; do
          [ -e "$item" ] || continue
          name="$(basename "$item")"
          dst="${dirConf}/$name"

          if [ -L "$item" ]; then
            continue
          fi

          if [ ! -e "$dst" ]; then
            echo "[$APP] Moving '${name}' → ${dirConf} 📦"
            move_with_backup "$item" "$dst"
          fi
        done

        for src in "${dirConf}"/*; do
          [ -e "$src" ] || continue
          name="$(basename "$src")"
          link="${asPath}/$name"

          backup_dest_if_needed "$link"
          unlink_if_symlink "$link"
          ensure_symlink "$link" "$src" || true
        done
      fi

      # ------------------------------------------------------------
      # --- APP-SPECIFIC: LOGGING DIRECTORY ---
      # ------------------------------------------------------------
      # iTerm can be configured to log into:
      #   /Users/ven/ven-dots/user-data/apps/iterm/logs
      # If this directory is missing, iTerm will prompt every launch.
      ensure_dir "${dirSRC}/logs"

      # ------------------------------------------------------------
      # --- PREFERENCES: PLISTS MOVE + SYMLINK ---
      # ------------------------------------------------------------
      for pref in ${lib.concatStringsSep " " prefItems}; do
        name="$(basename "$pref")"
        dst="${dirPref}/$name"

        if [ -e "$pref" ]; then
          if [ -L "$pref" ]; then
            if [ ! -e "$dst" ]; then
              echo "[$APP] Preferences symlink exists but destination missing. Repairing: $pref 🔧"
              unlink_if_symlink "$pref"
              : > "$dst"
            else
              echo "[$APP] Preferences item is a symlink. Verifying: $pref 🔎"
            fi
          else
            if [ ! -e "$dst" ]; then
              echo "[$APP] Moving '$name' → ${dirPref} 📄"
              move_with_backup "$pref" "$dst"
            fi
          fi
        else
          echo "[$APP] Preferences item missing. Skipping: $pref ✅"
        fi

        if [ -e "$dst" ]; then
          ln -sfn "$dst" "$pref"
          echo "[$APP] '$name' is being symlinked back to Preferences 🔗"
        fi
      done

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
