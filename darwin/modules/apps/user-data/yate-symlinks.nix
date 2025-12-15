# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/yate-symlinks.nix
#
# DARWIN: YATE USER-DATA
# ============================================================
# Yate is an audio metadata editor.
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/yate
#
# Runtime locations:
#   ~/Library/Application Support/Yate
#   ~/Library/Preferences/com.2manyrobots.Yate.plist
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder = "yate";
  asDirName = "Yate";

  asPath    = "${home}/Library/Application Support/${asDirName}";
  plist     = "${home}/Library/Preferences/com.2manyrobots.Yate.plist";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.2manyrobots.Yate.plist";
in
{
  home.activation.yateUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: Yate"

      mkdir -p "${dotRoot}"

      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        for item in "${asPath}"/*; do
          [ -e "$item" ] || continue
          name="$(basename "$item")"
          [ -e "${dotRoot}/$name" ] || mv "$item" "${dotRoot}/$name"
        done
      fi
      mkdir -p "${asPath}"

      for item in "${dotRoot}"/*; do
        name="$(basename "$item")"
        case "$name" in *.plist) continue ;; esac
        ln -sfn "$item" "${asPath}/$name"
      done

      [ -f "${plist}" ] && [ ! -f "${dotPlist}" ] && mv "${plist}" "${dotPlist}"
      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      ln -sfn "${dotPlist}" "${plist}"

      echo "Done: Yate"
    '';
}
