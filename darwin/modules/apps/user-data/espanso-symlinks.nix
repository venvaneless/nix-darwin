# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/espanso-symlinks.nix
#
# DARWIN: ESPANSO USER-DATA
# ============================================================
# Espanso is a text expansion and productivity tool for macOS.
#
# Moves app state into ven-dots and symlinks it back:
#   - Application Support directory
#   - Preferences plist
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/espanso
# ============================================================

{ config, lib, ... }:

let
  # PATHS
  # ------------------------------------------------------------
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder = "espanso";

  asPath    = "${home}/Library/Application Support/espanso";
  prefPlist = "${home}/Library/Preferences/com.federicoterzi.espanso.plist";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.federicoterzi.espanso.plist";
in
{
  home.activation.espansoUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: Espanso"

      # DOTFILES: ENSURE ROOT EXISTS
      # ------------------------------------------------------------
      mkdir -p "${dotRoot}"

      # APPLICATION SUPPORT: MIGRATE + SYMLINK
      # ------------------------------------------------------------
      if [ -L "${asPath}" ]; then
        rm -f "${asPath}"
      fi

      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        echo "Migrating Application Support → dotfiles"
        mv "${asPath}/"* "${dotRoot}/" 2>/dev/null || true
        rmdir "${asPath}" 2>/dev/null || true
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"

      # PREFERENCES: MIGRATE + SYMLINK
      # ------------------------------------------------------------
      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPlist}" ]; then
        echo "Moving plist → dotfiles"
        mv "${prefPlist}" "${dotPlist}"
      fi

      if [ ! -f "${dotPlist}" ]; then
        : > "${dotPlist}"
      fi

      ln -sfn "${dotPlist}" "${prefPlist}"

      echo "Done: Espanso"
    '';
}
