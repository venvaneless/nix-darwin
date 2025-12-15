# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/espanso-symlinks.nix
#
# DARWIN: ESPANSO USER-DATA
# ============================================================
# Espanso is a system-wide text expansion and productivity tool.
#
# SOURCE OF TRUTH:
#   /Users/ven/ven-dots/user-data/apps/espanso
#
# RUNTIME LOCATIONS:
#   ~/Library/Application Support/espanso
#   ~/Library/Preferences/com.federicoterzi.espanso.plist
#
# RESPONSIBILITIES:
#   - Move Application Support directory into dotfiles
#   - Symlink it back under the original name
#   - Move preferences plist into dotfiles
#   - Symlink plist back
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder  = "espanso";
  asRealName = "espanso";

  asPath    = "${home}/Library/Application Support/${asRealName}";
  prefPlist = "${home}/Library/Preferences/com.federicoterzi.espanso.plist";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.federicoterzi.espanso.plist";
in
{
  home.activation.espansoUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[Espanso] Syncing user-data"

      mkdir -p "${dotsApp}"

      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        mv "${asPath}" "${dotRoot}"
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPlist}" ]; then
        mv "${prefPlist}" "${dotPlist}"
      fi

      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      ln -sfn "${dotPlist}" "${prefPlist}"

      echo "Espanso: Done: User-data sync complete"
    '';
}
