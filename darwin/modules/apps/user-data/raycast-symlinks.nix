# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/raycast-symlinks.nix
#
# RAYCAST: USER-DATA MIDDLE-MAN
# ============================================================
# Source of truth:
#     /Users/ven/ven-dots/user-data/apps/raycast
#
# Runtime paths:
#     ~/Library/Application Support/com.raycast.macos
#     ~/Library/Preferences/com.raycast.macos.plist
#     ~/.config/raycast
#
# Responsibilities:
#   - Ensure dotfiles path exists (initialize from system if needed)
#   - Ensure Application Support/com.raycast.macos is a SYMLINK → dotfiles/pref
#   - Ensure ~/.config/raycast is a SYMLINK → dotfiles/conf
#   - Ensure Preferences plist lives in dotfiles/pref and is symlinked
#   - Never overwrite dotfiles
#   - Never partially symlink contents (folders only)
#   - Never install, update, or launch Raycast
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  # MAIN RAYCAST DOTFILES ROOT
  dotRaycast = "/Users/ven/ven-dots/user-data/apps/raycast";

  # SOURCE-OF-TRUTH DIRECTORIES
  dotPref = "${dotRaycast}/pref";   # Application Support contents
  dotConf = "${dotRaycast}/conf";   # ~/.config/raycast contents

  # PLIST (lives inside pref)
  dotPlist = "${dotPref}/com.raycast.macos.plist";

  # RUNTIME PATHS
  asPath    = "${home}/Library/Application Support/com.raycast.macos";
  plistPath = "${home}/Library/Preferences/com.raycast.macos.plist";
  confPath  = "${home}/.config/raycast";
in
{
  home.activation.raycastUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing Raycast user-data..."

      # ------------------------------------------------------------
      # Ensure dotfiles roots exist
      # ------------------------------------------------------------
      mkdir -p "${dotPref}"
      mkdir -p "${dotConf}"

      # ------------------------------------------------------------
      # APPLICATION SUPPORT → dotfiles/pref (FOLDER SYMLINK)
      # ------------------------------------------------------------
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        if [ "$(ls -A "${dotPref}" 2>/dev/null || true)" != "" ]; then
          echo "WARNING: ${asPath} exists and dotfiles/pref is not empty. Skipping move."
        else
          echo "Moving Application Support → dotfiles/pref"
          mv "${asPath}" "${dotPref}"
        fi
      fi

      if [ ! -L "${asPath}" ] || [ "$(readlink "${asPath}")" != "${dotPref}" ]; then
        rm -rf "${asPath}"
        ln -sfn "${dotPref}" "${asPath}"
        echo "Symlinked Application Support → dotfiles/pref"
      else
        echo "Application Support symlink already correct."
      fi

      # ------------------------------------------------------------
      # ~/.config/raycast → dotfiles/conf (FOLDER SYMLINK)
      # ------------------------------------------------------------
      if [ -d "${confPath}" ] && [ ! -L "${confPath}" ]; then
        if [ "$(ls -A "${dotConf}" 2>/dev/null || true)" != "" ]; then
          echo "WARNING: ~/.config/raycast exists and dotfiles/conf is not empty. Skipping move."
        else
          echo "Moving ~/.config/raycast → dotfiles/conf"
          mv "${confPath}" "${dotConf}"
        fi
      fi

      if [ ! -L "${confPath}" ] || [ "$(readlink "${confPath}")" != "${dotConf}" ]; then
        rm -rf "${confPath}"
        ln -sfn "${dotConf}" "${confPath}"
        echo "Symlinked ~/.config/raycast → dotfiles/conf"
      else
        echo "~/.config/raycast symlink already correct."
      fi

      # ------------------------------------------------------------
      # PREFERENCES PLIST (FILE SYMLINK)
      # ------------------------------------------------------------
      if [ -f "${plistPath}" ] && [ ! -L "${plistPath}" ] && [ ! -f "${dotPlist}" ]; then
        echo "Moving real plist → dotfiles"
        mv "${plistPath}" "${dotPlist}"
      fi

      [ -f "${dotPlist}" ] || : > "${dotPlist}"

      if [ ! -L "${plistPath}" ] || [ "$(readlink "${plistPath}")" != "${dotPlist}" ]; then
        rm -f "${plistPath}"
        ln -sfn "${dotPlist}" "${plistPath}"
        echo "Symlinked plist → dotfiles"
      else
        echo "Plist symlink already correct."
      fi

      echo "Raycast: User-data sync complete"
    '';
}
