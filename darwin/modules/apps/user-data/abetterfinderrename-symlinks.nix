# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/abetterfinderrename-symlinks.nix
#
# A BETTER FINDER RENAME USER-DATA
# ============================================================
# A Better Finder Rename is a bulk renaming utility for macOS.
#
# Stores all user data in ~/Library/Preferences:
# - net.publicspace.abfr12.plist
# - ABFR Registration
#
# This module migrates both into ven-dots and symlinks them back.
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder = "a_better_finder_rename";

  plistPath = "${home}/Library/Preferences/net.publicspace.abfr12.plist";
  regPath   = "${home}/Library/Preferences/ABFR Registration";

  dotRoot   = "${dotsApp}/${appFolder}";
  dotPlist  = "${dotRoot}/net.publicspace.abfr12.plist";
  dotReg    = "${dotRoot}/ABFR Registration";
in
{
  home.activation.abfrUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: A Better Finder Rename"

      mkdir -p "${dotRoot}"

      # ------------------------------------------------------------
      # PLIST
      # ------------------------------------------------------------
      if [ -f "${plistPath}" ] && [ ! -L "${plistPath}" ] && [ ! -f "${dotPlist}" ]; then
        mv "${plistPath}" "${dotPlist}"
      fi

      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      ln -sfn "${dotPlist}" "${plistPath}"

      # ------------------------------------------------------------
      # REGISTRATION FILE
      # ------------------------------------------------------------
      if [ -f "${regPath}" ] && [ ! -L "${regPath}" ] && [ ! -f "${dotReg}" ]; then
        mv "${regPath}" "${dotReg}"
      fi

      [ -f "${dotReg}" ] || : > "${dotReg}"
      ln -sfn "${dotReg}" "${regPath}"

      echo "Done: A Better Finder Rename"
    '';
}
