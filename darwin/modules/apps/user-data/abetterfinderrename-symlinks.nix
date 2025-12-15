# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/a-better-finder-rename-symlinks.nix
#
# DARWIN: A BETTER FINDER RENAME USER-DATA
# ============================================================
# A Better Finder Rename is a bulk file renaming tool.
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/a_better_finder_rename
#
# Runtime locations:
#   ~/Library/Application Support/A Better Finder Rename 12
#   ~/Library/Preferences/net.publicspace.abfr12.plist
#   ~/Library/Preferences/ABFR Registration
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder = "a_better_finder_rename";
  asDirName = "A Better Finder Rename 12";

  asPath   = "${home}/Library/Application Support/${asDirName}";
  plist    = "${home}/Library/Preferences/net.publicspace.abfr12.plist";
  regFile  = "${home}/Library/Preferences/ABFR Registration";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/net.publicspace.abfr12.plist";
  dotReg   = "${dotRoot}/ABFR Registration";
in
{
  home.activation.abfrUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: A Better Finder Rename"

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
        case "$name" in *.plist|"ABFR Registration") continue ;; esac
        ln -sfn "$item" "${asPath}/$name"
      done

      [ -f "${plist}" ] && [ ! -f "${dotPlist}" ] && mv "${plist}" "${dotPlist}"
      [ -f "${regFile}" ] && [ ! -f "${dotReg}" ] && mv "${regFile}" "${dotReg}"

      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      [ -f "${dotReg}" ]   || : > "${dotReg}"

      ln -sfn "${dotPlist}" "${plist}"
      ln -sfn "${dotReg}"   "${regFile}"

      echo "Done: A Better Finder Rename"
    '';
}
