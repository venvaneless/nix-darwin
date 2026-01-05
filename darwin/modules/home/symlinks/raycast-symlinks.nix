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
# - ~/.config/raycast/extensions/                 → <dirSRC>/extensions
# - ~/.config/raycast/ai/                         → <dirSRC>/ai
# - ~/Library/Application Support/com.raycast.*   → <dirSRC>/app_support/com.raycast.*
# - ~/Library/Preferences/com.raycast.macos.plist → <dirSRC>/com.raycast.macos.plist
# - ~/.config/raycast/ca.pem                      → <dirSRC>/ca.pem
# - ~/.config/raycast/config.json                 → <dirSRC>/config.json
#
# Safety model:
# - Copies folders as folders (no pre-created subdirs)
# - Never deletes destination content
# - Never creates empty backup folders
# - No symlinks, no filesystem tricks
# - Never blocks Home Manager activation
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  dirRoot = "/Users/ven/ven-dots/user-data/apps";
  appSlug = "raycast";
  dirSRC  = "${dirRoot}/${appSlug}";

  # Runtime paths
  rcRoot = "${home}/.config/raycast";
  rcExt  = "${rcRoot}/extensions";
  rcAI   = "${rcRoot}/ai";
  rcCa   = "${rcRoot}/ca.pem";
  rcConf = "${rcRoot}/config.json";

  asRoot = "${home}/Library/Application Support";
  asMac  = "${asRoot}/com.raycast.macos";
  asShared = "${asRoot}/com.raycast.shared";

  prefPlist = "${home}/Library/Preferences/com.raycast.macos.plist";

  # Backup containers
  dotAppSupport = "${dirSRC}/app_support";
in
{
  home.activation.raycastUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      APP="Raycast"
      echo "[$APP] User-data backup starting… 🚀"

      ensure_dir() {
        if [ ! -d "$1" ]; then
          echo "[$APP] Creating directory: $1 📁"
          mkdir -p "$1" || true
        fi
      }

      copy_dir_atomic() {
        local src="$1"
        local dstParent="$2"

        if [ ! -d "$src" ]; then
          echo "[$APP] Missing directory. Skipping: $src ✅"
          return
        fi

        if [ -z "$(ls -A "$src" 2>/dev/null || true)" ]; then
          echo "[$APP] Directory exists but is empty. Skipping: $src ⚠️"
          return
        fi

        local name
        name="$(basename "$src")"
        local dst="''${dstParent}/''${name}"

        ensure_dir "$dstParent"

        echo "[$APP] Copying directory: $src → $dst 📦"
        cp -a "$src" "$dst" || echo "[$APP] Failed copying directory: $src ❌"
      }

      copy_file_simple() {
        local src="$1"
        local dst="$2"

        if [ ! -e "$src" ]; then
          echo "[$APP] Missing file. Skipping: $src ✅"
          return
        fi

        ensure_dir "$(dirname "$dst")"

        echo "[$APP] Copying file: $src → $dst 📄"
        cp -p "$src" "$dst" || echo "[$APP] Failed copying file: $src ❌"
      }

      # Root destination
      ensure_dir "${dirSRC}"

      # ~/.config/raycast
      copy_dir_atomic "${rcExt}" "${dirSRC}"
      copy_dir_atomic "${rcAI}"  "${dirSRC}"

      copy_file_simple "${rcCa}"   "${dirSRC}/ca.pem"
      copy_file_simple "${rcConf}" "${dirSRC}/config.json"

      # Application Support (two folders into app_support/)
      copy_dir_atomic "${asMac}"    "${dotAppSupport}"
      copy_dir_atomic "${asShared}" "${dotAppSupport}"

      # Preferences plist
      copy_file_simple "${prefPlist}" "${dirSRC}/com.raycast.macos.plist"

      echo "[$APP] User-data backup complete ✅"
    '';
}
