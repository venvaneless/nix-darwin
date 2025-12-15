# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/yate-symlinks.nix
#
# DARWIN: YATE USER-DATA
# ============================================================
# Yate is an advanced audio metadata editor.
#
# SOURCE OF TRUTH:
#   /Users/ven/ven-dots/user-data/apps/yate
#
# RUNTIME LOCATIONS:
#   ~/Library/Application Support/Yate
#   ~/Library/Preferences/com.2manyrobots.Yate.plist
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder  = "yate";
  asRealName = "Yate";

  asPath    = "${home}/Library/Application Support/${asRealName}";
  prefPlist = "${home}/Library/Preferences/com.2manyrobots.Yate.plist";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.2manyrobots.Yate.plist";
in
{
  home.activation.yateUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[Yate] Syncing user-data"

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

      echo "Yate: Done: User-data sync complete"
    '';
}
