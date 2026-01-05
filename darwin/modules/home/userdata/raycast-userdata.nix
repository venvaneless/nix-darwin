# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/userdata/raycast-userdata.nix
#
# DARWIN: RAYCAST USER-DATA
# ============================================================
# Raycast launcher user-data backup (mirror, no symlinks).
#
# Backup destination (repo):
# - /Users/ven/ven-dots/user-data/apps/raycast
#
# What is backed up:
# - ~/.config/raycast/extensions/                 → <dirSRC>/extensions
# - ~/.config/raycast/ai/                         → <dirSRC>/ai
# - ~/Library/Application Support/com.raycast.*   → <dirSRC>/app_support/com.raycast.*
# - ~/Library/Preferences/com.raycast.macos.plist → <dirSRC>/com.raycast.macos.plist
# - ~/.config/raycast/ca.pem                      → <dirSRC>/ca.pem
# - ~/.config/raycast/config.json                 → <dirSRC>/config.json
#
# Sync model:
# - Destination is a strict mirror of runtime state
# - New / modified files are copied
# - Removed files are removed from destination
#
# Safety model:
# - No symlinks
# - Deletions strictly scoped to Raycast backup directory
# - Uses Nix-provided tools only
# - macOS-safe mtime handling
# - Never blocks Home Manager activation
# ============================================================

{ config, lib, pkgs, ... }:

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

  asRoot   = "${home}/Library/Application Support";
  asMac    = "${asRoot}/com.raycast.macos";
  asShared = "${asRoot}/com.raycast.shared";

  prefPlist = "${home}/Library/Preferences/com.raycast.macos.plist";

  # Backup containers
  dotAppSupport = "${dirSRC}/app_support";

  rsyncBin = "${pkgs.rsync}/bin/rsync";
in
{
  home.activation.raycastUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      APP="Raycast"
      echo "[$APP] User-data backup starting… 🚀"

      # ------------------------------------------------------------
      # --- HELPERS ---
      # ------------------------------------------------------------
      ensure_dir() {
        if [ ! -d "$1" ]; then
          echo "[$APP] Creating directory: $1 📁"
          mkdir -p "$1" || return 1
        fi
        return 0
      }

      file_mtime() {
        if [ -e "$1" ]; then
          date -r "$1" +%s 2>/dev/null || echo 0
        else
          echo 0
        fi
      }

      mirror_dir() {
        local src="$1"
        local dst="$2"

        if [ ! -d "$src" ]; then
          if [ -d "$dst" ]; then
            echo "[$APP] Source directory removed. Deleting backup: $dst 🧹"
            rm -rf "$dst" || true
          else
            echo "[$APP] Missing source directory. Skipping: $src ✅"
          fi
          return
        fi

        ensure_dir "$dst"

        echo "[$APP] Mirroring directory: $src → $dst 📦"
        if ${rsyncBin} -a --delete --itemize-changes "$src"/ "$dst"/; then
          echo "[$APP] Directory mirror complete: $dst ✅"
        else
          echo "[$APP] rsync failed (no abort): $src ⚠️"
        fi
      }

      mirror_file() {
        local src="$1"
        local dst="$2"

        if [ ! -e "$src" ]; then
          if [ -e "$dst" ]; then
            echo "[$APP] Source file removed. Deleting backup: $dst 🧹"
            rm -f "$dst" || true
          else
            echo "[$APP] Missing source file. Skipping: $src ✅"
          fi
          return
        fi

        local sm dm
        sm="$(file_mtime "$src")"
        dm="$(file_mtime "$dst")"

        if [ "$sm" -gt "$dm" ]; then
          ensure_dir "$(dirname "$dst")"
          echo "[$APP] Updating file: $src → $dst 📄"
          cp -p "$src" "$dst" || echo "[$APP] Failed copying file: $src ❌"
        else
          echo "[$APP] File up-to-date. Skipping: $src ✅"
        fi
      }

      # ------------------------------------------------------------
      # --- DESTINATION ROOT ---
      # ------------------------------------------------------------
      if ! ensure_dir "${dirSRC}"; then
        echo "[$APP] Failed to create backup root. Skipping ❌"
        exit 0
      fi

      # ------------------------------------------------------------
      # --- ~/.config/raycast ---
      # ------------------------------------------------------------
      mirror_dir "${rcExt}"  "${dirSRC}/extensions"
      mirror_dir "${rcAI}"   "${dirSRC}/ai"

      mirror_file "${rcCa}"   "${dirSRC}/ca.pem"
      mirror_file "${rcConf}" "${dirSRC}/config.json"

      # ------------------------------------------------------------
      # --- Application Support ---
      # ------------------------------------------------------------
      mirror_dir "${asMac}"    "${dotAppSupport}/com.raycast.macos"
      mirror_dir "${asShared}" "${dotAppSupport}/com.raycast.shared"

      # ------------------------------------------------------------
      # --- Preferences plist ---
      # ------------------------------------------------------------
      mirror_file "${prefPlist}" "${dirSRC}/com.raycast.macos.plist"

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data backup complete ✅"
    '';
}
