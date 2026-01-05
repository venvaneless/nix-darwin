# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/abetterfinderattributes-symlinks.nix
#
# DARWIN: A BETTER FINDER ATTRIBUTES USER-DATA
# ============================================================
# Bulk file attribute editor.
#
# Source of truth:
# - Preferences plist lives directly in:  /Users/ven/ven-dots/user-data/apps
#
# Runtime paths (what the app still "sees"):
# - ~/Library/Preferences/net.publicspace.abfa7.plist
#
# RULES
# -----
# - Only ONE plist is managed
# - Plist is MOVED once, then SYMLINKED
# - No backups required (symlinked file)
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  dotsRoot = "/Users/ven/ven-dots/user-data/apps";

  prefPlist = "${home}/Library/Preferences/net.publicspace.abfa7.plist";
  dotPlist  = "${dotsRoot}/net.publicspace.abfa7.plist";
in
{
  home.activation.abfaUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="A Better Finder Attributes"
      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH ---
      # ------------------------------------------------------------
      mkdir -p "${dotsRoot}"

      name="$(basename "${prefPlist}")"

      # ------------------------------------------------------------
      # --- PLIST MOVE + SYMLINK ---
      # ------------------------------------------------------------
      if [ -e "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -e "${dotPlist}" ]; then
        echo "[$APP] Moving '$name' → source-of-truth 📄"
        mv "${prefPlist}" "${dotPlist}"
      fi

      if [ -e "${dotPlist}" ] && [ ! -L "${prefPlist}" ]; then
        echo "[$APP] Symlinking '$name' back to Preferences 🔗"
        ln -s "${dotPlist}" "${prefPlist}"
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
