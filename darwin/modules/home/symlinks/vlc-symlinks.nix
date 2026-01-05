# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/vlc-symlinks.nix
#
# DARWIN: VLC USER-DATA
# ============================================================
# VLC is a media player for macOS.
#
# Source of truth:
# - Application Support folder lives in:     <dirSRC>/conf
# - Preferences folder + plist live in:     <dirSRC>/pref
#
# Runtime paths (what VLC still "sees"):
# - ~/Library/Application Support/org.videolan.vlc
# - ~/Library/Preferences/org.videolan.vlc
# - ~/Library/Preferences/org.videolan.vlc.plist
#
# Safety model:
# - "conf/" existence does NOT count as pollution
# - "pref/" existence does NOT count as pollution
# - "Polluted" means real migrated artifacts exist, or unexpected items exist
# - Exception: if runtime paths are NOT symlinks, they are repaired
#   ONLY when destination source-of-truth is empty / missing (per-path)
# - Never creates duplicate profiles
# - Never overwrites existing dotfiles
# - CFPreferences exception (plist only): may create an empty destination plist
#   to prevent macOS from recreating a real runtime plist and resetting settings
# ============================================================

{ config, lib, ... }:

let
  # ------------------------------------------------------------
  # --- PATHS ---
  # ------------------------------------------------------------
  home = config.home.homeDirectory;

  # Source-of-truth root for all apps
  dirRoot = "/Users/ven/ven-dots/user-data/apps";

  # App slug
  appSlug = "vlc";

  # Source-of-truth directories
  dirSRC  = "${dirRoot}/${appSlug}";
  dirConf = "${dirSRC}/conf";
  dirPref = "${dirSRC}/pref";

  # Application Support runtime folder
  asRealName = "org.videolan.vlc";
  asPath     = "${home}/Library/Application Support/${asRealName}";

  # Preferences runtime
  prefDirRuntime   = "${home}/Library/Preferences/org.videolan.vlc";
  prefPlistRuntime = "${home}/Library/Preferences/org.videolan.vlc.plist";

  # Preferences source-of-truth
  prefDirDot   = "${dirPref}/org.videolan.vlc";
  prefPlistDot = "${dirPref}/org.videolan.vlc.plist";
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
          mkdir -p "$d" || true
        fi
      }

      dir_is_empty() {
        [ -d "$1" ] || return 0
        [ -z "$(ls -A "$1" 2>/dev/null || true)" ]
      }

      path_is_symlink() {
        [ -L "$1" ]
      }

      unlink_if_symlink() {
        [ -L "$1" ] && {
          echo "[$APP] Removing existing symlink: $1 🧹"
          unlink "$1" || true
        }
      }

      backup_runtime_item() {
        local p="$1"
        if [ -e "$p" ] && [ ! -L "$p" ]; then
          local ts backup
          ts="$(date +%Y%m%d-%H%M%S)"
          backup="$p.backup-$ts"
          echo "[$APP] Runtime collision. Backing up: $p → $backup 📦"
          mv "$p" "$backup" || true
        fi
      }

      ensure_symlink() {
        local link="$1"
        local target="$2"

        if [ -L "$link" ]; then
          if [ "$(readlink "$link")" = "$target" ]; then
            echo "[$APP] Symlink OK: $link → $target ✅"
            return 0
          fi
          unlink_if_symlink "$link"
        elif [ -e "$link" ]; then
          echo "[$APP] Not a symlink at: $link (will not delete automatically) ⚠️"
          return 1
        fi

        echo "[$APP] Creating symlink: $link → $target 🔗"
        ln -s "$target" "$link" || true
      }

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH SETUP ---
      # ------------------------------------------------------------
      ensure_dir "${dirSRC}"
      ensure_dir "${dirConf}"
      ensure_dir "${dirPref}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT: MOVE + SYMLINK ---
      # ------------------------------------------------------------
      if path_is_symlink "${asPath}"; then
        echo "[$APP] Runtime Application Support already symlinked. Verifying 🔎"
        ensure_symlink "${asPath}" "${dirConf}" || true
      elif [ -d "${asPath}" ]; then
        if dir_is_empty "${dirConf}"; then
          echo "[$APP] Migrating Application Support → conf 📦"
          mv "${asPath}" "${dirConf}" || true
        else
          echo "[$APP] conf already populated. Skipping migration ⚠️"
          backup_runtime_item "${asPath}"
        fi
        ensure_symlink "${asPath}" "${dirConf}" || true
      else
        ensure_symlink "${asPath}" "${dirConf}" || true
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES DIRECTORY ---
      # ------------------------------------------------------------
      if path_is_symlink "${prefDirRuntime}"; then
        ensure_symlink "${prefDirRuntime}" "${prefDirDot}" || true
      elif [ -e "${prefDirRuntime}" ]; then
        if dir_is_empty "${prefDirDot}"; then
          echo "[$APP] Migrating preferences directory → pref 📦"
          mv "${prefDirRuntime}" "${prefDirDot}" || true
        else
          backup_runtime_item "${prefDirRuntime}"
        fi
        ensure_symlink "${prefDirRuntime}" "${prefDirDot}" || true
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES PLIST (CFPreferences-safe) ---
      # ------------------------------------------------------------
      if path_is_symlink "${prefPlistRuntime}"; then
        [ -e "${prefPlistDot}" ] || {
          echo "[$APP] Creating destination plist for CFPreferences 🧩"
          : > "${prefPlistDot}" || true
        }
        ensure_symlink "${prefPlistRuntime}" "${prefPlistDot}" || true
      elif [ -e "${prefPlistRuntime}" ]; then
        if [ -e "${prefPlistDot}" ]; then
          backup_runtime_item "${prefPlistRuntime}"
        else
          echo "[$APP] Migrating preferences plist → pref 📄"
          mv "${prefPlistRuntime}" "${prefPlistDot}" || true
        fi
        ensure_symlink "${prefPlistRuntime}" "${prefPlistDot}" || true
      else
        if [ -e "${prefPlistDot}" ]; then
          ensure_symlink "${prefPlistRuntime}" "${prefPlistDot}" || true
        else
          echo "[$APP] Creating empty plist for CFPreferences 🧩"
          : > "${prefPlistDot}" || true
          ensure_symlink "${prefPlistRuntime}" "${prefPlistDot}" || true
        fi
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
