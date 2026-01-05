# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/forklift-symlinks.nix
#
# DARWIN: FORKLIFT USER-DATA
# ============================================================
# ForkLift file manager user-data handling.
#
# MODEL
# -----
# - Application Support is user-owned and redirected
# - Runtime folder name MUST remain "ForkLift"
# - Preferences plist is moved and symlinked back
#
# SOURCE OF TRUTH
# ----------------
#   /Users/ven/ven-dots/user-data/apps/ForkLift/
#     ├─ app_support/          (Application Support content)
#     └─ com.binarynights.ForkLift.plist
#
# RUNTIME PATHS (UNCHANGED)
# ------------------------
#   ~/Library/Application Support/ForkLift
#   ~/Library/Preferences/com.binarynights.ForkLift.plist
#
# RULES
# -----
# - Runtime folder name NEVER changes
# - No empty files are created
# - Existing data is reused
# - No partial migrations
# - Safe to run repeatedly
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  # ------------------------------------------------------------
  # SOURCE OF TRUTH
  # ------------------------------------------------------------
  dotRoot = "/Users/ven/ven-dots/user-data/apps/ForkLift";
  dotAS   = "${dotRoot}/app_support";
  dotPlist = "${dotRoot}/com.binarynights.ForkLift.plist";

  # ------------------------------------------------------------
  # RUNTIME PATHS
  # ------------------------------------------------------------
  rtAS    = "${home}/Library/Application Support/ForkLift";
  rtPlist = "${home}/Library/Preferences/com.binarynights.ForkLift.plist";
in
{
  home.activation.forkliftUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      APP="ForkLift"

      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # HELPERS
      # ------------------------------------------------------------
      ensure_dir() {
        if [ ! -d "$1" ]; then
          echo "[$APP] Creating directory: $1 📁"
          mkdir -p "$1"
        fi
      }

      unlink_if_symlink() {
        if [ -L "$1" ]; then
          echo "[$APP] Removing existing symlink: $1 🧹"
          unlink "$1"
        fi
      }

      # ------------------------------------------------------------
      # SOURCE OF TRUTH SETUP
      # ------------------------------------------------------------
      ensure_dir "${dotRoot}"
      ensure_dir "${dotAS}"

      # ------------------------------------------------------------
      # APPLICATION SUPPORT (MOVE + SYMLINK)
      # ------------------------------------------------------------
      if [ -L "${rtAS}" ]; then
        echo "[$APP] Application Support already a symlink. Verifying… 🔎"

        if [ "$(readlink "${rtAS}")" != "${dotAS}" ]; then
          echo "[$APP] Fixing Application Support symlink 🔧"
          unlink_if_symlink "${rtAS}"
          ln -s "${dotAS}" "${rtAS}"
        else
          echo "[$APP] Application Support symlink OK ✅"
        fi

      elif [ -d "${rtAS}" ]; then
        if [ -z "$(ls -A "${dotAS}" 2>/dev/null || true)" ]; then
          echo "[$APP] Moving Application Support → ${dotAS} 📦"
          mv "${rtAS}" "${dotAS}"

          echo "[$APP] Symlinking Application Support back 🔗"
          ln -s "${dotAS}" "${rtAS}"
        else
          echo "[$APP] Source-of-truth already populated. Skipping AS migration ⚠️"
        fi

      else
        echo "[$APP] No Application Support folder found. Skipping AS step ✅"
      fi

      # ------------------------------------------------------------
      # PREFERENCES PLIST (MOVE + SYMLINK)
      # ------------------------------------------------------------
      if [ -L "${rtPlist}" ]; then
        echo "[$APP] Preferences plist already a symlink. Verifying… 🔎"

        if [ "$(readlink "${rtPlist}")" != "${dotPlist}" ]; then
          echo "[$APP] Fixing plist symlink 🔧"
          unlink_if_symlink "${rtPlist}"
          ln -s "${dotPlist}" "${rtPlist}"
        else
          echo "[$APP] Preferences symlink OK ✅"
        fi

      elif [ -e "${rtPlist}" ]; then
        if [ ! -e "${dotPlist}" ]; then
          echo "[$APP] Moving plist → source-of-truth 📄"
          mv "${rtPlist}" "${dotPlist}"
        fi

        if [ ! -L "${rtPlist}" ]; then
          echo "[$APP] Symlinking plist back 🔗"
          ln -s "${dotPlist}" "${rtPlist}"
        fi

      else
        echo "[$APP] Preferences plist missing. Skipping ✅"
      fi

      echo "[$APP] User-data sync complete ✅"
    '';
}
