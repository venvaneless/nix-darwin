# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/abetterfinderrename-symlinks.nix
#
# DARWIN: A BETTER FINDER RENAME USER-DATA
# ============================================================
# Bulk file renaming utility.
#
# SOURCE OF TRUTH:
#   /Users/ven/ven-dots/user-data/apps/a_better_finder_rename
#
# RUNTIME LOCATIONS:
#   ~/Library/Application Support/A Better Finder Rename 12
#   ~/Library/Preferences/net.publicspace.abfr12.plist
#   ~/Library/Preferences/ABFR Registration
# ============================================================

{ config, lib, ... }:

let
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  appFolder  = "a_better_finder_rename";
  asRealName = "A Better Finder Rename 12";

  asPath = "${home}/Library/Application Support/${asRealName}";

  plist = "${home}/Library/Preferences/net.publicspace.abfr12.plist";
  reg   = "${home}/Library/Preferences/ABFR Registration";

  dotRoot  = "${dotsApp}/${appFolder}";
  dotPrefs = "${dotRoot}/Preferences";
in
{
  home.activation.abfrUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "[ABFR] Syncing user-data"

      mkdir -p "${dotsApp}"

      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        mv "${asPath}" "${dotRoot}"
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"

      mkdir -p "${dotPrefs}"

      [ -f "${plist}" ] && [ ! -f "${dotPrefs}/$(basename "${plist}")" ] && mv "${plist}" "${dotPrefs}/"
      [ -f "${reg}" ]   && [ ! -f "${dotPrefs}/$(basename "${reg}")" ]   && mv "${reg}"   "${dotPrefs}/"

      ln -sfn "${dotPrefs}/$(basename "${plist}")" "${plist}"
      ln -sfn "${dotPrefs}/$(basename "${reg}")"   "${reg}"

      echo "A Better Finder Rename: Done: User-data sync complete"
    '';
}
