# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/raycast-symlinks.nix
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
#   - Move real system folders/files into dotfiles if needed (ONE-TIME)
#   - Ensure Application Support folders are SYMLINKS → dotfiles (STABLE)
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
  plistPath    = "${home}/Library/Preferences/com.raycast.macos.plist";
  confPath     = "${home}/.config/raycast";
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
      mkdir -p "${home}/.config"

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

      if [ ! -L "${confPath}" ] || [ "$(readlink "${confPath}" 2>/dev/null || true)" != "${dotConf}" ]; then
        rm -rf "${confPath}"
        ln -sfn "${dotConf}" "${confPath}"
        echo "Symlinked ~/.config/raycast → dotfiles/conf"
      else
        echo "~/.config/raycast symlink already correct."
      fi

      # ------------------------------------------------------------
      # Application Support: com.raycast.macos
      # IMPORTANT: do NOT pre-create ${dotMacos} if we might mv into it,
      # or mv will nest: ${dotMacos}/com.raycast.macos/...
      # ------------------------------------------------------------
      mkdir -p "$(dirname "${dotMacos}")"

      if [ -d "${asMacosPath}" ] && [ ! -L "${asMacosPath}" ]; then
        if [ -e "${dotMacos}" ]; then
          if [ -d "${dotMacos}" ] && [ "$(ls -A "${dotMacos}" 2>/dev/null || true)" = "" ]; then
            echo "dotfiles com.raycast.macos exists but is empty placeholder — removing to allow move."
            rmdir "${dotMacos}" 2>/dev/null || rm -rf "${dotMacos}"
            echo "Moving Application Support/com.raycast.macos → dotfiles"
            mv "${asMacosPath}" "${dotMacos}"
          else
            echo "WARNING: dotfiles com.raycast.macos already exists and is not empty. Skipping move."
          fi
        else
          echo "Moving Application Support/com.raycast.macos → dotfiles"
          mv "${asMacosPath}" "${dotMacos}"
        fi
      fi

      if [ ! -L "${asMacosPath}" ] || [ "$(readlink "${asMacosPath}" 2>/dev/null || true)" != "${dotMacos}" ]; then
        rm -rf "${asMacosPath}"
        ln -sfn "${dotMacos}" "${asMacosPath}"
        echo "Symlinked com.raycast.macos → dotfiles"
      else
        echo "com.raycast.macos symlink already correct."
      fi

      # ------------------------------------------------------------
      # Application Support: com.raycast.shared
      # Same nesting bug fix as above.
      # ------------------------------------------------------------
      mkdir -p "$(dirname "${dotShared}")"

      if [ -d "${asSharedPath}" ] && [ ! -L "${asSharedPath}" ]; then
        if [ -e "${dotShared}" ]; then
          if [ -d "${dotShared}" ] && [ "$(ls -A "${dotShared}" 2>/dev/null || true)" = "" ]; then
            echo "dotfiles com.raycast.shared exists but is empty placeholder — removing to allow move."
            rmdir "${dotShared}" 2>/dev/null || rm -rf "${dotShared}"
            echo "Moving Application Support/com.raycast.shared → dotfiles"
            mv "${asSharedPath}" "${dotShared}"
          else
            echo "WARNING: dotfiles com.raycast.shared already exists and is not empty. Skipping move."
          fi
        else
          echo "Moving Application Support/com.raycast.shared → dotfiles"
          mv "${asSharedPath}" "${dotShared}"
        fi
      fi

      if [ ! -L "${asSharedPath}" ] || [ "$(readlink "${asSharedPath}" 2>/dev/null || true)" != "${dotShared}" ]; then
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

      if [ ! -L "${plistPath}" ] || [ "$(readlink "${plistPath}" 2>/dev/null || true)" != "${dotPlist}" ]; then
        rm -f "${plistPath}" 2>/dev/null || true
        ln -sfn "${dotPlist}" "${plistPath}"
        echo "Symlinked plist → dotfiles"
      else
        echo "Preferences plist symlink already correct."
      fi

      echo "Raycast: User-data sync complete"
    '';
}
