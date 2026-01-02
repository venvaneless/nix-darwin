# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/raycast-symlinks.nix
#
# DARWIN: RAYCAST USER-DATA
# ============================================================
# Raycast launcher user-data management.
#
# Source of truth:
# - Application Support content lives in:  <dirSRC>/appsupport
# - Config directory lives in:             <dirSRC>/conf
# - Preferences plist lives in:            <dirSRC>
#
# Runtime paths (what Raycast still "sees"):
# - ~/Library/Application Support/com.raycast.macos
# - ~/Library/Application Support/com.raycast.shared
# - ~/.config/raycast
# - ~/Library/Preferences/com.raycast.macos.plist
#
# Safety model:
# - Runtime directories remain REAL directories
# - Only CONTENTS are migrated and symlinked
# - Existing data is ALWAYS migrated first
# - Never creates duplicate or empty state
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
  appSlug = "raycast";

  # App source-of-truth directories
  dirSRC        = "${dirRoot}/${appSlug}";
  dirConf       = "${dirSRC}/conf";
  dirAppSupport = "${dirSRC}/appsupport";

  # Runtime Application Support paths (MUST KEEP NAMES)
  asMacosName   = "com.raycast.macos";
  asSharedName  = "com.raycast.shared";

  asMacosPath   = "${home}/Library/Application Support/${asMacosName}";
  asSharedPath  = "${home}/Library/Application Support/${asSharedName}";

  # Dotfiles Application Support paths
  dotMacosPath  = "${dirAppSupport}/${asMacosName}";
  dotSharedPath = "${dirAppSupport}/${asSharedName}";

  # Runtime config + plist
  runtimeConf   = "${home}/.config/raycast";
  prefPlist     = "${home}/Library/Preferences/com.raycast.macos.plist";

  # Dotfiles plist
  dotPlist      = "${dirSRC}/com.raycast.macos.plist";
in
{
  home.activation.raycastUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="Raycast"
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
          echo "[$APP] Removing existin
