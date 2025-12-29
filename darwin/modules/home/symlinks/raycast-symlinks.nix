# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/raycast-symlinks.nix
#
# RAYCAST: USER-DATA MIDDLE-MAN (SAFE, NON-DESTRUCTIVE)
# ============================================================
# RULES:
#   - NEVER delete Raycast data
#   - NEVER rm -rf Application Support paths
#   - ONLY move aside (timestamped backup)
#   - ONLY then create symlinks
#   - Idempotent across rebuilds
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  tsCmd = "date +%Y%m%d-%H%M%S";

  # DOTFILES ROOT (LOCAL, NON-ICLOUD)
  dotRaycast = "/Users/ven/ven-dots/user-data/apps/raycast";

  dotMacos  = "${dotRaycast}/com.raycast.macos";
  dotShared = "${dotRaycast}/com.raycast.shared";
  dotConf   = "${dotRaycast}/conf";
  dotPlist  = "${dotRaycast}/com.raycast.macos.plist";

  asMacosPath  = "${home}/Library/Application Support/com.raycast.macos";
  asSharedPath = "${home}/Library/Application Support/com.raycast.shared";
  plistPath   = "${home}/Library/Preferences/com.raycast.macos.plist";
  confPath    = "${home}/.config/raycast";
in
{
  home.activation.raycastUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      echo "Raycast HM: starting safe user-data sync"

      mkdir -p "${dotRaycast}"
      mkdir -p "${dotConf}"
      mkdir -p "${home}/.config"

      # ------------------------------------------------------------
      # ~/.config/raycast  (SAFE)
      # ------------------------------------------------------------
      if [ -e "${confPath}" ] && { [ ! -L "${confPath}" ] || [ "$(readlink "${confPath}" 2>/dev/null || true)" != "${dotConf}" ]; }; then
        ts="$(${tsCmd})"
        echo "Backing up ~/.config/raycast → ${confPath}.bak-${ts}"
        mv "${confPath}" "${confPath}.bak-${ts}"
      fi

      if [ ! -L "${confPath}" ]; then
        ln -sfn "${dotConf}" "${confPath}"
        echo "Symlinked ~/.config/raycast → dotfiles"
      fi

      # ------------------------------------------------------------
      # Application Support: com.raycast.macos  (SAFE)
      # ------------------------------------------------------------
      mkdir -p "$(dirname "${dotMacos}")"

      if [ -e "${asMacosPath}" ] && { [ ! -L "${asMacosPath}" ] || [ "$(readlink "${asMacosPath}" 2>/dev/null || true)" != "${dotMacos}" ]; }; then
        ts="$(${tsCmd})"
        echo "Backing up com.raycast.macos → ${asMacosPath}.bak-${ts}"
        mv "${asMacosPath}" "${asMacosPath}.bak-${ts}"
      fi

      if [ ! -L "${asMacosPath}" ]; then
        ln -sfn "${dotMacos}" "${asMacosPath}"
        echo "Symlinked com.raycast.macos → dotfiles"
      fi

      # ------------------------------------------------------------
      # Application Support: com.raycast.shared  (SAFE)
      # ------------------------------------------------------------
      mkdir -p "$(dirname "${dotShared}")"

      if [ -e "${asSharedPath}" ] && { [ ! -L "${asSharedPath}" ] || [ "$(readlink "${asSharedPath}" 2>/dev/null || true)" != "${dotShared}" ]; }; then
        ts="$(${tsCmd})"
        echo "Backing up com.raycast.shared → ${asSharedPath}.bak-${ts}"
        mv "${asSharedPath}" "${asSharedPath}.bak-${ts}"
      fi

      if [ ! -L "${asSharedPath}" ]; then
        ln -sfn "${dotShared}" "${asSharedPath}"
        echo "Symlinked com.raycast.shared → dotfiles"
      fi

      # ------------------------------------------------------------
      # Preferences plist  (SAFE)
      # ------------------------------------------------------------
      if [ -e "${plistPath}" ] && { [ ! -L "${plistPath}" ] || [ "$(readlink "${plistPath}" 2>/dev/null || true)" != "${dotPlist}" ]; }; then
        ts="$(${tsCmd})"
        echo "Backing up plist → ${plistPath}.bak-${ts}"
        mv "${plistPath}" "${plistPath}.bak-${ts}"
      fi

      if [ ! -f "${dotPlist}" ]; then
        : > "${dotPlist}"
      fi

      if [ ! -L "${plistPath}" ]; then
        ln -sfn "${dotPlist}" "${plistPath}"
        echo "Symlinked plist → dotfiles"
      fi

      echo "Raycast HM: user-data sync complete (safe mode)"
    '';
}
