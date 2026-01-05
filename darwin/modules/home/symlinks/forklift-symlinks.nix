# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/forklift-symlinks.nix
#
# DARWIN: FORKLIFT USER-DATA
# ============================================================
# ForkLift file manager user-data handling.
#
# SOURCE OF TRUTH
# ----------------
#   /Users/ven/ven-dots/user-data/apps/forklift
#     ├── app_support
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
# - Empty Application Support directories are still migrated
# - No empty plist files are created
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  dirRoot = "/Users/ven/ven-dots/user-data/apps";
  appSlug = "forklift";

  dirSRC = "${dirRoot}/${appSlug}";
  dirAS  = "${dirSRC}/app_support";

  rtAS    = "${home}/Library/Application Support/ForkLift";
  rtPlist = "${home}/Library/Preferences/com.binarynights.ForkLift.plist";

  dotPlist = "${dirSRC}/com.binarynights.ForkLift.plist";
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

      ensure_dir() {
        [ -d "$1" ] || {
          echo "[$APP] Creating directory: $1 📁"
          mkdir -p "$1" || true
        }
      }

      path_is_symlink() { [ -L "$1" ]; }

      unlink_if_symlink() {
        [ -L "$1" ] && unlink "$1" || true
      }

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH SETUP ---
      # ------------------------------------------------------------
      ensure_dir "${dirSRC}"
      ensure_dir "${dirAS}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      if path_is_symlink "${rtAS}"; then
        ln -sfn "${dirAS}" "${rtAS}"
      elif [ -d "${rtAS}" ]; then
        echo "[$APP] Migrating Application Support → app_support 📦"
        mv "${rtAS}" "${dirAS}" || true
        ln -s "${dirAS}" "${rtAS}"
      else
        ln -s "${dirAS}" "${rtAS}"
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES PLIST ---
      # ------------------------------------------------------------
      if path_is_symlink "${rtPlist}"; then
        ln -sfn "${dotPlist}" "${rtPlist}"
      elif [ -e "${rtPlist}" ]; then
        echo "[$APP] Migrating preferences plist → source of truth 📄"
        mv "${rtPlist}" "${dotPlist}" || true
        ln -s "${dotPlist}" "${rtPlist}"
      elif [ -e "${dotPlist}" ]; then
        ln -s "${dotPlist}" "${rtPlist}"
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
