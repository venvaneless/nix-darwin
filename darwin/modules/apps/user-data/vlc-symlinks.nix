# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/vlc-symlinks.nix
#
# DARWIN: VLC USER-DATA
# ============================================================
# VLC is a media player for macOS.
#
# This module relocates VLC user data into ven-dots so it can be
# versioned, backed up, and synced as a single source of truth.
#
# ------------------------------------------------------------
# SOURCE OF TRUTH
# ------------------------------------------------------------
#   /Users/ven/ven-dots/user-data/apps/vlc
#
# This directory is ALWAYS:
#   - a real directory
#   - never a symlink
#   - the authoritative location for VLC state
#
# ------------------------------------------------------------
# RUNTIME LOCATIONS (macOS EXPECTS THESE)
# ------------------------------------------------------------
#   ~/Library/Application Support/org.videolan.vlc
#   ~/Library/Preferences/org.videolan.vlc.plist
#
# ------------------------------------------------------------
# RESPONSIBILITIES
# ------------------------------------------------------------
#   - Ensure dotfiles root exists
#   - Move VLC Application Support directory into dotfiles
#   - Recreate Application Support path as a symlink
#   - Move VLC plist into dotfiles
#   - Symlink plist back to Preferences
#
# ------------------------------------------------------------
# IMPORTANT
# ------------------------------------------------------------
#   - No symlinks are ever created INSIDE the dotfiles folder
#   - The Application Support DIRECTORY is the unit of state
#   - Folder names may differ between dotfiles and runtime
# ============================================================

{ config, lib, ... }:

let
  # ------------------------------------------------------------
  # PATH ROOTS
  # ------------------------------------------------------------
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  # ------------------------------------------------------------
  # APP IDENTIFIERS
  # ------------------------------------------------------------
  appFolder  = "vlc";
  asRealName = "org.videolan.vlc";

  # ------------------------------------------------------------
  # RUNTIME PATHS (EXPECTED BY macOS)
  # ------------------------------------------------------------
  asPath    = "${home}/Library/Application Support/${asRealName}";
  prefPlist = "${home}/Library/Preferences/org.videolan.vlc.plist";

  # ------------------------------------------------------------
  # DOTFILES PATHS (SOURCE OF TRUTH)
  # ------------------------------------------------------------
  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/org.videolan.vlc.plist";
in
{
  home.activation.vlcUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[VLC] Syncing user-data"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH ---
      # ------------------------------------------------------------
      mkdir -p "${dotsApp}"

      if [ ! -d "${dotRoot}" ]; then
        echo "[VLC] ${dotRoot} doesn't exist for VLC yet. Creating. 📁"
        mkdir -p "${dotRoot}"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        if [ -e "${dotRoot}" ] && [ "$(ls -A "${dotRoot}" 2>/dev/null || true)" != "" ]; then
          echo "[VLC] WARNING: '${asRealName}' exists in Application Support and '${dotRoot}' is not empty. Skipping move. ⚠️"
        else
          echo "[VLC] '${asRealName}' is being moved from Application Support to ${dotRoot} 📦"
          rm -rf "${dotRoot}" 2>/dev/null || true
          mv "${asPath}" "${dotRoot}"
          echo "[VLC] '${asRealName}' has been successfully moved from ${asPath} to ${dotRoot} ✅"
        fi
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"
      echo "[VLC] '${asRealName}' is being symlinked back to ${asPath} 🔗"

      # ------------------------------------------------------------
      # --- PREFERENCES ---
      # ------------------------------------------------------------
      name="$(basename "${prefPlist}")"

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -e "${dotPlist}" ]; then
        echo "[VLC] '$name' is being moved from Preferences to ${dotRoot} 📄"
        mv "${prefPlist}" "${dotPlist}"
        echo "[VLC] '$name' has been successfully moved from ${prefPlist} to ${dotPlist} ✅"
      fi

      [ -e "${dotPlist}" ] || : > "${dotPlist}"

      ln -sfn "${dotPlist}" "${prefPlist}"
      echo "[VLC] '$name' is being symlinked back to ${prefPlist} 🔗"

      echo "VLC: User-data sync complete ✅"
    '';
}
