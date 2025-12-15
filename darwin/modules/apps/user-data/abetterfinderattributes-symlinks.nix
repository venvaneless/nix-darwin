# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/a-better-finder-attributes-symlinks.nix
#
# DARWIN: A BETTER FINDER ATTRIBUTES USER-DATA
# ============================================================
# Bulk file attribute editor.
#
# SOURCE OF TRUTH:
#   /Users/ven/ven-dots/user-data/apps/a_better_finder_attributes
#
# RUNTIME LOCATIONS:
#   ~/Library/Application Support/A Better Finder Attributes
#   ~/Library/Preferences/com.publicspace.abfa.plist
#   ~/Library/Preferences/net.publicspace.abfa7.plist
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder  = "a_better_finder_attributes";
  asRealName = "A Better Finder Attributes";

  asPath = "${home}/Library/Application Support/${asRealName}";

  plistA = "${home}/Library/Preferences/com.publicspace.abfa.plist";
  plistB = "${home}/Library/Preferences/net.publicspace.abfa7.plist";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPrefs = "${dotRoot}/Preferences";
in
{
  home.activation.abfaUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[ABFA] Syncing user-data"

      mkdir -p "${dotsApp}"

      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        mv "${asPath}" "${dotRoot}"
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"

      mkdir -p "${dotPrefs}"

      [ -f "${plistA}" ] && [ ! -f "${dotPrefs}/$(basename "${plistA}")" ] && mv "${plistA}" "${dotPrefs}/"
      [ -f "${plistB}" ] && [ ! -f "${dotPrefs}/$(basename "${plistB}")" ] && mv "${plistB}" "${dotPrefs}/"

      ln -sfn "${dotPrefs}/$(basename "${plistA}")" "${plistA}"
      ln -sfn "${dotPrefs}/$(basename "${plistB}")" "${plistB}"

      echo "A Better Finder Attributes: Done: User-data sync complete"
    '';
}
