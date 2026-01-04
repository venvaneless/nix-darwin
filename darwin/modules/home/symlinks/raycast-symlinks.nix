# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/raycast-symlinks.nix
#
# DARWIN: RAYCAST USER-DATA
# ============================================================
# Raycast launcher user-data backup.
#
# Backup destination (repo):
# - /Users/ven/ven-dots/user-data/apps/raycast
#
# What is backed up (no symlinks):
# - ~/Library/Application Support/com.raycast.macos/   → <dirSRC>/app_support
# - ~/Library/Preferences/com.raycast.macos.plist     → <dirSRC>/com.raycast.macos.plist
# - ~/.config/raycast/extensions/                     → <dirSRC>/extensions
# - ~/.config/raycast/ai/                             → <dirSRC>/ai
# - ~/.config/raycast/ca.pem                          → <dirSRC>/ca.pem
# - ~/.config/raycast/config.json                     → <dirSRC>/config.json
#
# Safety model:
# - Does NOT create or manage symlinks
# - Does NOT delete any destination content
# - Copies only when source is newer / changed
# - Never touches iCloud paths
# - Never blocks Home Manager activation
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
  appSlug = "raycast";

  # Backup destination root
  dirSRC = "${dirRoot}/${appSlug}";

  # Application Support (runtime)
  asName = "com.raycast.macos";
  asPath = "${home}/Library/Application Support/${asName}";

  # Application Support (backup destination, renamed)
  dotAppSupport = "${dirSRC}/app_support";

  # Preferences plist (runtime)
  prefPlist = "${home}/Library/Preferences/com.raycast.macos.plist";

  # Preferences plist (backup destination)
  dotPlist = "${dirSRC}/com.raycast.macos.plist";

  # Raycast config root (runtime)
  rcRoot = "${home}/.config/raycast";

  # Runtime config dirs
  rcExt = "${rcRoot}/extensions";
  rcAI  = "${rcRoot}/ai";

  # Runtime config files
  rcCa   = "${rcRoot}/ca.pem";
  rcConf = "${rcRoot}/config.json";

  # Backup destinations
  dotExt  = "${dirSRC}/extensions";
  dotAI   = "${dirSRC}/ai";
  dotCa   = "${dirSRC}/ca.pem";
  dotConf = "${dirSRC}/config.json";
in
{
  home.activation.raycastUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="Raycast"
      echo "[$APP] User-data backup starting… 🚀"

      # ------------------------------------------------------------
      # --- HELPERS: SAFE DIRECTORY CREATION ---
      # ------------------------------------------------------------
      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d 📁"
          mkdir -p "$d" || true
        fi
      }

      # ------------------------------------------------------------
      # --- HELPERS: SAFE FILE COPY (mtime-aware) ---
      # Copies only if source exists and is newer than destination
      # ------------------------------------------------------------
      copy_file_if_newer() {
        local src="$1"
        local dst="$2"

        if [ ! -e "$src" ]; then
          echo "[$APP] Missing source file. Skipping: $src ✅"
          return 0
        fi

        ensure_dir "$(dirname "$dst")"

        if [ -e "$dst" ]; then
          local sm dm
          sm="$(stat -f %m "$src" 2>/dev/null || echo 0)"
          dm="$(stat -f %m "$dst" 2>/dev/null || echo 0)"

          if [ "$sm" = "$dm" ]; then
            echo "[$APP] File unchanged. Skipping: $src ✅"
            return 0
          fi

          if [ "$sm" -le "$dm" ]; then
            echo "[$APP] Destination newer or same. Skipping: $dst ✅"
            return 0
          fi
        fi

        echo "[$APP] Copying file: $src → $dst 📄"
        cp -p "$src" "$dst" || true
        echo "[$APP] File copied: $dst ✅"
      }

      # ------------------------------------------------------------
      # --- HELPERS: SAFE DIRECTORY SYNC (no deletes) ---
      # Uses rsync to copy only newer/changed items.
      # No --delete is used (destination never gets wiped).
      # ------------------------------------------------------------
      sync_dir_update_only() {
        local src="$1"
        local dst="$2"

        if [ ! -d "$src" ]; then
          echo "[$APP] Missing source directory. Skipping: $src ✅"
          return 0
        fi

        ensure_dir "$dst"

        echo "[$APP] Syncing directory (update-only): $src → $dst 📦"
        rsync -a --update "$src"/ "$dst"/ 2>/dev/null || rsync -a -u "$src"/ "$dst"/ || true
        echo "[$APP] Directory sync complete: $dst ✅"
      }

      # ------------------------------------------------------------
      # --- DESTINATION ROOT ---
      # ------------------------------------------------------------
      ensure_dir "${dirSRC}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT BACKUP ---
      # ~/Library/Application Support/com.raycast.macos → <dirSRC>/app_support
      # ------------------------------------------------------------
      sync_dir_update_only "${asPath}" "${dotAppSupport}"

      # ------------------------------------------------------------
      # --- PREFERENCES PLIST BACKUP ---
      # ~/Library/Preferences/com.raycast.macos.plist → <dirSRC>/com.raycast.macos.plist
      # ------------------------------------------------------------
      copy_file_if_newer "${prefPlist}" "${dotPlist}"

      # ------------------------------------------------------------
      # --- ~/.config/raycast BACKUP ---
      # extensions/ and ai/ are directories
      # ca.pem and config.json are files
      # ------------------------------------------------------------
      sync_dir_update_only "${rcExt}" "${dotExt}"
      sync_dir_update_only "${rcAI}"  "${dotAI}"

      copy_file_if_newer "${rcCa}"   "${dotCa}"
      copy_file_if_newer "${rcConf}" "${dotConf}"

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data backup complete ✅"
    '';
}
