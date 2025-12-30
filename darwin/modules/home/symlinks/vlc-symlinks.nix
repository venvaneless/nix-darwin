# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/vlc-symlinks.nix
#
# DARWIN: VLC USER-DATA
# ============================================================
# VLC is a media player for macOS.
#
# Source of truth:
# - Application Support content lives in:  <dirSRC>/conf
# - Preferences directory lives in:        <dirSRC>/pref
# - Preferences plist lives in:            <dirSRC>
#
# Runtime paths (what VLC still "sees"):
# - ~/Library/Application Support/org.videolan.vlc
# - ~/Library/Preferences/org.videolan.vlc
# - ~/Library/Preferences/org.videolan.vlc.plist
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
  appSlug = "vlc";

  # App source-of-truth directories
  dirSRC  = "${dirRoot}/${appSlug}";
  dirConf = "${dirSRC}/conf";
  dirPref = "${dirSRC}/pref";

  # Application Support runtime path
  asRealName = "org.videolan.vlc";
  asPath     = "${home}/Library/Application Support/${asRealName}";

  # Preferences runtime directory + plist
  prefDir   = "${home}/Library/Preferences/${asRealName}";
  prefPlist = "${home}/Library/Preferences/org.videolan.vlc.plist";

  # Preferences dotfiles destinations
  dotPrefDir = "${dirPref}/${asRealName}";
  dotPlist   = "${dirSRC}/org.videolan.vlc.plist";
in
{
  home.activation.vlcUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="VLC"
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
          else
            echo "[$APP] Application Support is not a symlink. Repairing into ${dirConf} 🔧"
          fi

          move_with_backup "${asPath}" "${dirConf}"
        fi
      else
        echo "[$APP] No Application Support data found. Skipping Application Support ✅"
      fi

      # Critical: avoid creating ${asPath}/conf via ln behavior
      backup_dest_if_needed "${asPath}"
      unlink_if_symlink "${asPath}"

      ln -sfn "${dirConf}" "${asPath}"
      echo "[$APP] Application Support symlinked → ${dirConf} 🔗"

      # ------------------------------------------------------------
      # --- PREFERENCES: DIRECTORY MOVE + SYMLINK ---
      # ------------------------------------------------------------
      if [ -e "${prefDir}" ]; then
        if [ -L "${prefDir}" ]; then
          echo "[$APP] Preferences directory is a symlink. Verifying… 🔎"
        else
          if [ "$allowMigrate" = "1" ]; then
            echo "[$APP] Moving '${asRealName}' preferences directory → ${dirPref} 📄"
          else
            echo "[$APP] Preferences directory is not a symlink. Repairing into ${dirPref} 🔧"
          fi

          move_with_backup "${prefDir}" "${dotPrefDir}"
        fi
      else
        echo "[$APP] Preferences directory missing. Skipping: ${prefDir} ✅"
      fi

      # Ensure runtime path becomes a symlink (and does not become ${prefDir}/${asRealName})
      backup_dest_if_needed "${prefDir}"
      unlink_if_symlink "${prefDir}"

      ln -sfn "${dotPrefDir}" "${prefDir}"
      echo "[$APP] Preferences directory symlinked → ${dotPrefDir} 🔗"

      # ------------------------------------------------------------
      # --- PREFERENCES: PLIST MOVE + SYMLINK ---
      # ------------------------------------------------------------
      name="$(basename "${prefPlist}")"

      if [ -e "${prefPlist}" ]; then
        if [ -L "${prefPlist}" ]; then
          if [ ! -e "${dotPlist}" ]; then
            echo "[$APP] Preferences symlink exists but destination missing. Repairing: ${prefPlist} 🔧"
            unlink_if_symlink "${prefPlist}"
            : > "${dotPlist}"
          else
            echo "[$APP] Preferences item is a symlink. Verifying: ${prefPlist} 🔎"
          fi
        else
          if [ ! -e "${dotPlist}" ]; then
            echo "[$APP] Moving '$name' → ${dirSRC} 📄"
            move_with_backup "${prefPlist}" "${dotPlist}"
          fi
        fi
      else
        echo "[$APP] Preferences item missing. Skipping: ${prefPlist} ✅"
      fi

      if [ -e "${dotPlist}" ]; then
        ln -sfn "${dotPlist}" "${prefPlist}"
        echo "[$APP] '$name' is being symlinked back to Preferences 🔗"
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
