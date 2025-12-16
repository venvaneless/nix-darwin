# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/abetterfinderattributes-symlinks.nix
#
# DARWIN: A BETTER FINDER ATTRIBUTES USER-DATA
# ============================================================
# Bulk file attribute editor.
#
# Moves Application Support data into ven-dots and symlinks it back.
# Moves Preferences plists into ven-dots/Preferences and symlinks them back.
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
      echo "[ABFA] Starting user-data sync…"

      # ------------------------------------------------------------
      # SOURCE OF TRUTH SETUP
      # ------------------------------------------------------------
      if [ ! -d "${dotRoot}" ]; then
        echo "[ABFA] Source of truth missing. Creating ${dotRoot} 📁"
        mkdir -p "${dotRoot}"
      fi

      # ------------------------------------------------------------
      # APPLICATION SUPPORT: MOVE + SYMLINK
      # ------------------------------------------------------------
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        echo "[ABFA] '${asRealName}' is being moved from Application Support → ven-dots 📦"
        mv "${asPath}" "${dotRoot}"
        echo "[ABFA] '${asRealName}' successfully moved ✅"
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"
      echo "[ABFA] '${asRealName}' is being symlinked back to Application Support 🔗"

      # ------------------------------------------------------------
      # PREFERENCES: MOVE + SYMLINK
      # ------------------------------------------------------------
      mkdir -p "${dotPrefs}"

      for plist in "${plistA}" "${plistB}"; do
        name="$(basename "$plist")"
        if [ -f "$plist" ] && [ ! -f "${dotPrefs}/$name" ]; then
          echo "[ABFA] '$name' is being moved from Preferences → ${dotPrefs} 📄"
          mv "$plist" "${dotPrefs}/$name"
          echo "[ABFA] '$name' successfully moved ✅"
        fi

        ln -sfn "${dotPrefs}/$name" "$plist"
        echo "[ABFA] '$name' is being symlinked back to Preferences 🔗"
      done

      echo "A Better Finder Attributes: User-data sync complete ✅"
    '';
}
