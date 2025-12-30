# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/vlc-symlinks.nix
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
#   ~/Library/Preferences/org.videolan.vlc
#   ~/Library/Preferences/org.videolan.vlc.plist
#
# ------------------------------------------------------------
# RESPONSIBILITIES
# ------------------------------------------------------------
#   - Ensure dotfiles root exists
#   - Move VLC Application Support directory into dotfiles
#   - Recreate Application Support path as a symlink
#   - Move VLC Preferences directory into dotfiles
#   - Symlink Preferences directory back
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
  dirRoot = "/Users/ven/ven-dots/user-data/apps";

  # ------------------------------------------------------------
  # APP IDENTIFIERS
  # ------------------------------------------------------------
  appSlug    = "vlc";
  asRealName = "org.videolan.vlc";

  # ------------------------------------------------------------
  # SOURCE-OF-TRUTH PATHS
  # ------------------------------------------------------------
  dirSRC     = "${dirRoot}/${appSlug}";
  dirConf    = "${dirSRC}/conf";
  dirPref    = "${dirSRC}/pref";

  # ------------------------------------------------------------
  # RUNTIME PATHS
  # ------------------------------------------------------------
  asPath    = "${home}/Library/Application Support/${asRealName}";
  prefDir   = "${home}/Library/Preferences/${asRealName}";
  prefPlist = "${home}/Library/Preferences/org.videolan.vlc.plist";

  # ------------------------------------------------------------
  # DOTFILES PATHS
  # ------------------------------------------------------------
  dotPrefDir = "${dirPref}/${asRealName}";
  dotPlist   = "${dirSRC}/org.videolan.vlc.plist";
in
{
  home.activation.vlcUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      APP="VLC"

      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH SETUP ---
      # ------------------------------------------------------------
      mkdir -p "${dirSRC}"
      mkdir -p "${dirConf}"
      mkdir -p "${dirPref}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        if [ "$(ls -A "${dirConf}" 2>/dev/null || true)" != "" ]; then
          echo "[$APP] Application Support exists but source-of-truth not empty. Skipping move ⚠️"
        else
          echo "[$APP] Moving Application Support → ${dirConf} 📦"
          mv "${asPath}" "${dirConf}"
        fi
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dirConf}" "${asPath}"
      echo "[$APP] Application Support symlinked → ${dirConf} 🔗"

      # ------------------------------------------------------------
      # --- PREFERENCES DIRECTORY ---
      # ------------------------------------------------------------
      if [ -d "${prefDir}" ] && [ ! -L "${prefDir}" ] && [ ! -d "${dotPrefDir}" ]; then
        echo "[$APP] Moving preferences directory → ${dirPref} 📄"
        mv "${prefDir}" "${dotPrefDir}"
      fi

      rm -rf "${prefDir}" 2>/dev/null || true
      ln -sfn "${dotPrefDir}" "${prefDir}"
      echo "[$APP] Preferences directory symlinked → ${dotPrefDir} 🔗"

      # ------------------------------------------------------------
      # --- PREFERENCES PLIST ---
      # ------------------------------------------------------------
      name="$(basename "${prefPlist}")"

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -e "${dotPlist}" ]; then
        echo "[$APP] Moving plist → ${dotPlist} 📄"
        mv "${prefPlist}" "${dotPlist}"
      fi

      ln -sfn "${dotPlist}" "${prefPlist}"
      echo "[$APP] Preferences plist symlinked → ${dotPlist} 🔗"

      echo "[$APP] User-data sync complete ✅"
    '';
}
