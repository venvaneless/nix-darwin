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

      # ------------------------------------------------------------
      # --- HELPERS ---
      # ------------------------------------------------------------
      ensure_dir() {
        [ -d "$1" ] || {
          echo "[$APP] Creating directory: $1 📁"
          mkdir -p "$1" || true
        }
      }

      dir_is_empty() {
        [ -d "$1" ] || return 0
        [ -z "$(ls -A "$1" 2>/dev/null || true)" ]
      }

      path_is_symlink() { [ -L "$1" ]; }

      unlink_if_symlink() {
        [ -L "$1" ] && {
          echo "[$APP] Removing existing symlink: $1 🧹"
          unlink "$1" || true
        }
      }

      backup_runtime_item() {
        local p="$1"
        if [ -e "$p" ] && [ ! -L "$p" ]; then
          local ts backup
          ts="$(date +%Y%m%d-%H%M%S)"
          backup="$p.backup-$ts"

          echo "[$APP] Runtime collision. Backing up: $p → $backup 📦"
          mv "$p" "$backup" || true
        fi
      }

      ensure_symlink() {
        local link="$1"
        local target="$2"

        if path_is_symlink "$link"; then
          local cur
          cur="$(readlink "$link" || true)"
          [ "$cur" = "$target" ] && {
            echo "[$APP] Symlink OK: $link → $target ✅"
            return 0
          }
          echo "[$APP] Symlink wrong: $link → $cur (expected $target) ⚠️"
          unlink_if_symlink "$link"
        elif [ -e "$link" ]; then
          echo "[$APP] Not a symlink at: $link (will not delete) ⚠️"
          return 1
        fi

        echo "[$APP] Creating symlink: $link → $target 🔗"
        ln -s "$target" "$link" || true
        echo "[$APP] Symlink created: $link → $target ✅"
      }

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH SETUP ---
      # ------------------------------------------------------------
      ensure_dir "${dirSRC}"
      ensure_dir "${dirAS}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      # GOAL:
      # - Source-of-truth path MUST be: ${dirAS}
      # - Runtime folder name MUST stay: ${rtAS}
      # - NEVER create nested: ${dirAS}/ForkLift
      #
      # FIX:
      # - If migrating, rename the runtime folder INTO ${dirAS}
      #   (requires removing empty ${dirAS} first)
      # ------------------------------------------------------------
      if path_is_symlink "${rtAS}"; then
        echo "[$APP] Application Support already symlinked. Verifying… 🔎"
        ensure_symlink "${rtAS}" "${dirAS}" || true
      elif [ -d "${rtAS}" ]; then
        if dir_is_empty "${dirAS}"; then
          echo "[$APP] Migrating Application Support → app_support 📦"

          # If app_support exists (created earlier) and is empty, remove it so mv renames correctly.
          rmdir "${dirAS}" 2>/dev/null || true

          # Rename: <runtime folder> -> <dirAS>
          mv "${rtAS}" "${dirAS}" || true
        else
          echo "[$APP] app_support already populated. Skipping migration (will not overwrite) ⚠️"
          backup_runtime_item "${rtAS}"
        fi

        echo "[$APP] Symlinking Application Support back → runtime 🔗"
        ensure_symlink "${rtAS}" "${dirAS}" || true
      else
        echo "[$APP] Application Support missing. Creating symlink 🔗"
        ensure_symlink "${rtAS}" "${dirAS}" || true
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES PLIST ---
      # ------------------------------------------------------------
      if path_is_symlink "${rtPlist}"; then
        echo "[$APP] Preferences plist already symlinked. Verifying… 🔎"
        ensure_symlink "${rtPlist}" "${dotPlist}" || true
      elif [ -e "${rtPlist}" ]; then
        if [ -e "${dotPlist}" ]; then
          echo "[$APP] Destination plist exists. Repairing runtime into symlink 🔧"
          backup_runtime_item "${rtPlist}"
        else
          echo "[$APP] Migrating preferences plist → source of truth 📄"
          mv "${rtPlist}" "${dotPlist}" || true
        fi

        echo "[$APP] Symlinking preferences plist back → Preferences 🔗"
        ensure_symlink "${rtPlist}" "${dotPlist}" || true
      else
        if [ -e "${dotPlist}" ]; then
          echo "[$APP] Runtime plist missing; destination exists. Creating symlink 🔗"
          ensure_symlink "${rtPlist}" "${dotPlist}" || true
        else
          echo "[$APP] Preferences plist missing. Skipping ✅"
        fi
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
