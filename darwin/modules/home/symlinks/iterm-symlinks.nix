# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/iterm-symlinks.nix
#
# DARWIN: ITERM USER-DATA (FINAL, CORRECT)
# ============================================================
# iTerm2 user-data handling with strict ownership boundaries.
#
# MODEL
# -----
# - Application Support is managed by iTerm itself (DO NOT TOUCH)
# - conf/ is user-controlled and untouched here
# - Preference plists are handled explicitly and safely
#
# SOURCE OF TRUTH
# ----------------
#   /Users/ven/ven-dots/user-data/apps/iterm/pref
#
# RUNTIME PATHS (UNCHANGED)
# ------------------------
#   ~/Library/Preferences/com.googlecode.iterm2.plist
#   ~/Library/Preferences/com.googlecode.iterm2.private.plist
#
# RULES
# -----
# - Folder names NEVER change
# - No empty files are ever created
# - No partial migrations
# - Existing data is reused
# - Main plist is NEVER symlinked
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  # ------------------------------------------------------------
  # SOURCE OF TRUTH
  # ------------------------------------------------------------
  dotRoot = "/Users/ven/ven-dots/user-data/apps/iterm";
  dotPref = "${dotRoot}/pref";

  # ------------------------------------------------------------
  # RUNTIME PLISTS
  # ------------------------------------------------------------
  plistMain    = "${home}/Library/Preferences/com.googlecode.iterm2.plist";
  plistPrivate = "${home}/Library/Preferences/com.googlecode.iterm2.private.plist";
in
{
  home.activation.itermUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      APP="iTerm2"

      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # SOURCE OF TRUTH SETUP
      # ------------------------------------------------------------
      if [ ! -d "${dotPref}" ]; then
        echo "[$APP] Creating preferences source-of-truth: ${dotPref} 📁"
        mkdir -p "${dotPref}"
      fi

      # ------------------------------------------------------------
      # PREFERENCES — PRIVATE PLIST (MOVE + SYMLINK)
      # ------------------------------------------------------------
      privateDst="${dotPref}/com.googlecode.iterm2.private.plist"

      if [ -e "${plistPrivate}" ]; then
        if [ ! -L "${plistPrivate}" ] && [ ! -e "$privateDst" ]; then
        echo "[$APP] Moving private plist → $privateDst 📄"
          mv "${plistPrivate}" "$privateDst"
        fi

        if [ -e "$privateDst" ] && [ ! -L "${plistPrivate}" ]; then
          echo "[$APP] Symlinking private plist back → Preferences 🔗"
          ln -s "$privateDst" "${plistPrivate}"
        fi
      else
        echo "[$APP] Private plist missing. Skipping ✅"
      fi

      # ------------------------------------------------------------
      # PREFERENCES — MAIN PLIST (COPY ONLY, NEVER SYMLINK)
      # ------------------------------------------------------------
      mainDst="${dotPref}/com.googlecode.iterm2.plist"

      if [ -e "${plistMain}" ]; then
        if [ ! -e "$mainDst" ]; then
        echo "[$APP] Copying main plist → $mainDst 📄"
          cp -p "${plistMain}" "$mainDst"
        else
       	if ! cmp -s "${plistMain}" "$mainDst"; then
          echo "[$APP] Main plist changed. Updating copy 📄"
          cp -p "${plistMain}" "$mainDst"
        else
          echo "[$APP] Main plist unchanged. No copy needed ✅"
          fi
        fi
      else
        echo "[$APP] Main plist missing. Skipping ✅"
      fi

      echo "[$APP] User-data sync complete ✅"
    '';
}
