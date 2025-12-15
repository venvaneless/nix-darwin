# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/paste-symlinks.nix
#
# DARWIN: PASTE USER-DATA
# ============================================================
# Paste is a clipboard manager.
#
# IMPORTANT:
#   Paste DOES NOT tolerate Application Support relocation.
#   Only the preferences plist is managed here.
#
# SOURCE OF TRUTH:
#   /Users/ven/ven-dots/user-data/apps/paste
#
# RUNTIME LOCATION:
#   ~/Library/Preferences/com.wiheads.paste-direct.plist
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
      echo "[Paste] Syncing plist only"

      mkdir -p "${dotRoot}"

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "${dotPlist}" ]; then
        mv "${prefPlist}" "${dotPlist}"
      fi

      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      ln -sfn "${dotPlist}" "${prefPlist}"

      echo "Paste: Done: User-data sync complete"
    '';
}
