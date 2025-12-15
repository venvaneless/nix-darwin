# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/paste-symlinks.nix
#
# PASTE USER-DATA
# ============================================================
# Paste is a clipboard manager for macOS.
#
# User-owned preferences:
# - com.wiheads.paste-direct.plist
#
# System-owned Apple plists are intentionally ignored.
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder = "paste";

  prefPlist = "${home}/Library/Preferences/com.wiheads.paste-direct.plist";

  dotRoot   = "${dotsApp}/${appFolder}";
  dotPlist  = "${dotRoot}/com.wiheads.paste-direct.plist";
in
{
  home.activation.pasteUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: Paste"
      echo "NOTE: Close Paste during first migration."

      mkdir -p "${dotRoot}"

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPlist}" ]; then
        mv "${prefPlist}" "${dotPlist}"
      fi

      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      ln -sfn "${dotPlist}" "${prefPlist}"

      echo "Done: Paste"
    '';
}
