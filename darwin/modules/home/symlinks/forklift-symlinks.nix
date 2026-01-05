# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/forklift-symlinks.nix
#
# DARWIN: FORKLIFT USER-DATA
# ============================================================
# ForkLift file manager user-data handling.
#
# SOURCE OF TRUTH
# ----------------
#   /Users/ven/ven-dots/user-data/apps/forklift
#     ├── app_support/        ← Application Support contents
#     └── com.binarynights.ForkLift.plist
#
# RUNTIME PATHS (UNCHANGED)
# ------------------------
#   ~/Library/Application Support/ForkLift
#   ~/Library/Preferences/com.binarynights.ForkLift.plist
#
# RULES
# -----
# - Runtime folder name NEVER changes
# - Runtime folder itself becomes the symlink
# - No nested "ForkLift/" directories are ever created
# - No empty files are created
# - Existing data is migrated once, then reused
# - Safe for nix-darwin + Home Manager activation
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  # ------------------------------------------------------------
  # SOURCE OF TRUTH (CANONICAL, LOWERCASE)
  # ------------------------------------------------------------
  dotRoot = "/Users/ven/ven-dots/user-data/apps/forklift";
  dotAS   = "${dotRoot}/app_support";
  dotPlist = "${dotRoot}/com.binarynights.ForkLift.plist";

  # ------------------------------------------------------------
  # RUNTIME PATHS (MUST NOT CHANGE)
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
      # APPLICATION SUPPORT (MOVE ONCE + SYMLINK)
      # ------------------------------------------------------------
      if [ -L "${rtAS}" ]; then
        echo "[$APP] Application Support already symlinked. Verifying target… 🔎"
        ln -sfn "${dotAS}" "${rtAS}"
      elif [ -d "${rtAS}" ]; then
        if [ -z "$(ls -A "${dotAS}" 2>/dev/null || true)" ]; then
          echo "[$APP] Migrating Application Support → source of truth 📦"
          mv "${rtAS}"/* "${dotAS}/"
          rmdir "${rtAS}"
        else
          echo "[$APP] Source-of-truth already populated. Not re-migrating ⚠️"
          rm -rf "${rtAS}"
        fi

        echo "[$APP] Symlinking Application Support → dotfiles 🔗"
        ln -s "${dotAS}" "${rtAS}"
      else
        echo "[$APP] Application Support missing. Creating symlink 🔗"
        ln -s "${dotAS}" "${rtAS}"
      fi

      # ------------------------------------------------------------
      # PREFERENCES PLIST (MOVE ONCE + SYMLINK)
      # ------------------------------------------------------------
      if [ -L "${rtPlist}" ]; then
        echo "[$APP] Preferences plist already symlinked. Verifying… 🔎"
        ln -sfn "${dotPlist}" "${rtPlist}"
      elif [ -f "${rtPlist}" ]; then
        if [ ! -f "${dotPlist}" ]; then
          echo "[$APP] Migrating preferences plist → source of truth 📄"
          mv "${rtPlist}" "${dotPlist}"
        else
          echo "[$APP] Source plist exists. Removing runtime copy ⚠️"
          rm -f "${rtPlist}"
        fi

        echo "[$APP] Symlinking preferences plist back → Preferences 🔗"
        ln -s "${dotPlist}" "${rtPlist}"
      else
        if [ -f "${dotPlist}" ]; then
          echo "[$APP] Runtime plist missing. Creating symlink 🔗"
          ln -s "${dotPlist}" "${rtPlist}"
        else
          echo "[$APP] Preferences plist missing. Skipping (ForkLift will recreate) ⚠️"
        fi
      fi

      echo "[$APP] User-data sync complete ✅"
    '';
}