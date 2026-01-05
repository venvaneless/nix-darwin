# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/userdata/forklift-userdata.nix
#
# DARWIN: FORKLIFT USER-DATA
# ============================================================
# ForkLift file manager user-data handling.
#
# SOURCE OF TRUTH
# ----------------
#   /Users/ven/ven-dots/user-data/apps/com.binarynights.ForkLift.plist
#
# RUNTIME PATH (UNCHANGED)
# -----------------------
#   ~/Library/Preferences/com.binarynights.ForkLift.plist
#
# RULES
# -----
# - ONLY the preferences plist is managed
# - Plist is COPY-SYNCED (NEVER symlinked)
# - Newer runtime plist replaces source-of-truth
# - Safe to run repeatedly
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  dotsRoot = "/Users/ven/ven-dots/user-data/apps";

  rtPlist  = "${home}/Library/Preferences/com.binarynights.ForkLift.plist";
  dotPlist = "${dotsRoot}/com.binarynights.ForkLift.plist";
in
{
  home.activation.forkliftUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="ForkLift"
      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH ---
      # ------------------------------------------------------------
      mkdir -p "${dotsRoot}"

      # ------------------------------------------------------------
      # --- PLIST COPY-BASED SYNC ---
      # ------------------------------------------------------------
      if [ -e "${rtPlist}" ]; then
        if [ ! -e "${dotPlist}" ]; then
          echo "[$APP] Copying preferences plist → source-of-truth 📄"
          cp -p "${rtPlist}" "${dotPlist}"
        elif [ "${rtPlist}" -nt "${dotPlist}" ]; then
          echo "[$APP] Runtime plist newer. Updating source-of-truth 📄"
          cp -p "${rtPlist}" "${dotPlist}"
        else
          echo "[$APP] Source-of-truth plist is up to date ✅"
        fi
      else
        echo "[$APP] Runtime plist missing. Nothing to sync ⚠️"
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
