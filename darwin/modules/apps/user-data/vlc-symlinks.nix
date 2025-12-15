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
  # Normalized name used in ven-dots (lowercase, no spaces)
  appFolder = "vlc";

  # Actual folder name macOS / VLC uses
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
      # ENSURE DOTFILES ROOT EXISTS
      # ------------------------------------------------------------
      # This guarantees the source of truth always exists
      mkdir -p "${dotsApp}"

      # ------------------------------------------------------------
      # APPLICATION SUPPORT: MOVE → DOTFILES
      # ------------------------------------------------------------
      # If VLC has already created its Application Support folder,
      # and it is NOT a symlink, move it into ven-dots.
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        echo "[VLC] Moving Application Support → ven-dots"
        mv "${asPath}" "${dotRoot}"
      fi

      # ------------------------------------------------------------
      # APPLICATION SUPPORT: RECREATE AS SYMLINK
      # ------------------------------------------------------------
      # Ensure no leftover path exists, then recreate it
      # as a symlink pointing to the dotfiles location.
      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"

      # ------------------------------------------------------------
      # PREFERENCES: MOVE PLIST → DOTFILES
      # ------------------------------------------------------------
      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPlist}" ]; then
        echo "[VLC] Moving plist → ven-dots"
        mv "${prefPlist}" "${dotPlist}"
      fi

      # Ensure plist exists so the symlink target is valid
      [ -f "${dotPlist}" ] || : > "${dotPlist}"

      # ------------------------------------------------------------
      # PREFERENCES: SYMLINK PLIST BACK
      # ------------------------------------------------------------
      ln -sfn "${dotPlist}" "${prefPlist}"

      echo "VLC: Done: User-data sync complete"
    '';
}
