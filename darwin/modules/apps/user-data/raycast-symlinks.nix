# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/raycast-symlinks.nix
#
# RAYCAST: USER-DATA MIDDLE-MAN
# ============================================================
# Source of truth:
#     /Users/ven/ven-dots/user-data/apps/raycast
#
# Runtime paths:
#     ~/Library/Application Support/com.raycast.macos
#     ~/Library/Application Support/com.raycast.shared
#     ~/Library/Preferences/com.raycast.macos.plist
#     ~/.config/raycast
#
# Responsibilities:
#   - Ensure Raycast dotfiles root exists
#   - Move real system folders/files into dotfiles if needed
#   - Ensure Application Support folders are SYMLINKS → dotfiles
#   - Ensure ~/.config/raycast is a SYMLINK → dotfiles/conf
#   - Ensure Preferences plist is moved + symlinked
#   - Never overwrite dotfiles
#   - Never partially symlink contents (folders only)
#   - Never install, update, or launch Raycast
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  # MAIN RAYCAST DOTFILES ROOT
  dotRaycast = "/Users/ven/ven-dots/user-data/apps/raycast";

  # SOURCE-OF-TRUTH PATHS
  dotMacos   = "${dotRaycast}/com.raycast.macos";
  dotShared  = "${dotRaycast}/com.raycast.shared";
  dotConf    = "${dotRaycast}/conf";
  dotPlist   = "${dotRaycast}/com.raycast.macos.plist";

  # RUNTIME PATHS
  asMacosPath  = "${home}/Library/Application Support/com.raycast.macos";
  asSharedPath = "${home}/Library/Application Support/com.raycast.shared";
  plistPath   = "${home}/Library/Preferences/com.raycast.macos.plist";
  confPath    = "${home}/.config/raycast";
in
{
  home.activation.raycastUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing Raycast user-data..."

      # ------------------------------------------------------------
      # Ensure dotfiles root exists
      # ------------------------------------------------------------
      mkdir -p "${dotRaycast}"
      mkdir -p "${dotConf}"

      # ------------------------------------------------------------
      # ~/.config/raycast → dotfiles/conf
      # ------------------------------------------------------------
      if [ -d "${confPath}" ] && [ ! -L "${confPath}" ]; then
        if [ "$(ls -A "${dotConf}" 2>/dev/null || true)" != "" ]; then
          echo "WARNING: ~/.config/raycast exists and dotfiles/conf is not empty. Skipping move."
        else
          echo "Moving ~/.config/raycast → dotfiles/conf"
          rm -rf "${dotConf}"
          mv "${confPath}" "${dotConf}"
        fi
      fi

      mkdir -p "${home}/.config"

      if [ ! -L "${confPath}" ] || [ "$(readlink "${confPath}")" != "${dotConf}" ]; then
        rm -rf "${confPath}"
        ln -sfn "${dotConf}" "${confPath}"
        echo "Symlinked ~/.config/raycast → dotfiles/conf"
      else
        echo "~/.config/raycast symlink already correct."
      fi

      # ------------------------------------------------------------
      # Application Support: com.raycast.macos
      # ------------------------------------------------------------
      mkdir -p "${dotMacos}"

      if [ -d "${asMacosPath}" ] && [ ! -L "${asMacosPath}" ]; then
        if [ "$(ls -A "${dotMacos}" 2>/dev/null || true)" != "" ]; then
          echo "WARNING: com.raycast.macos exists and dotfiles copy is not empty. Skipping move."
        else
          echo "Moving Application Support/com.raycast.macos → dotfiles"
          rm -rf "${dotMacos}"
          mv "${asMacosPath}" "${dotMacos}"
        fi
      fi

      if [ ! -L "${asMacosPath}" ] || [ "$(readlink "${asMacosPath}")" != "${dotMacos}" ]; then
        rm -rf "${asMacosPath}"
        ln -sfn "${dotMacos}" "${asMacosPath}"
        echo "Symlinked com.raycast.macos → dotfiles"
      else
        echo "com.raycast.macos symlink already correct."
      fi

      # ------------------------------------------------------------
      # Application Support: com.raycast.shared
      # ------------------------------------------------------------
      mkdir -p "${dotShared}"

      if [ -d "${asSharedPath}" ] && [ ! -L "${asSharedPath}" ]; then
        if [ "$(ls -A "${dotShared}" 2>/dev/null || true)" != "" ]; then
          echo "WARNING: com.raycast.shared exists and dotfiles copy is not empty. Skipping move."
        else
          echo "Moving Application Support/com.raycast.shared → dotfiles"
          rm -rf "${dotShared}"
          mv "${asSharedPath}" "${dotShared}"
        fi
      fi

      if [ ! -L "${asSharedPath}" ] || [ "$(readlink "${asSharedPath}")" != "${dotShared}" ]; then
        rm -rf "${asSharedPath}"
        ln -sfn "${dotShared}" "${asSharedPath}"
        echo "Symlinked com.raycast.shared → dotfiles"
      else
        echo "com.raycast.shared symlink already correct."
      fi

      # ------------------------------------------------------------
      # Preferences plist
      # ------------------------------------------------------------
      if [ -f "${plistPath}" ] && [ ! -L "${plistPath}" ] && [ ! -f "${dotPlist}" ]; then
        echo "Moving real plist → dotfiles"
        mv "${plistPath}" "${dotPlist}"
      fi

      [ -f "${dotPlist}" ] || : > "${dotPlist}"

      if [ ! -L "${plistPath}" ] || [ "$(readlink "${plistPath}")" != "${dotPlist}" ]; then
        rm -f "${plistPath}" 2>/dev/null || true
        ln -sfn "${dotPlist}" "${plistPath}"
        echo "Symlinked plist → dotfiles"
      else
        echo "Preferences plist symlink already correct."
      fi

      echo "Raycast: User-data sync complete"
    '';
}
