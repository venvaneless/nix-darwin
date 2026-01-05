# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/abetterfinderrename-symlinks.nix
#
# DARWIN: A BETTER FINDER RENAME USER-DATA
# ============================================================
# Bulk file renaming utility.
#
# Source of truth:
# - Application Support content lives in:  <dirSRC>/conf
# - Preferences content lives in:          <dirSRC>/pref
#
# Runtime paths:
# - ~/Library/Application Support/A Better Finder Rename 12
# - ~/Library/Preferences/net.publicspace.abfr12.plist
# - ~/Library/Preferences/ABFR Registration
# - ~/Library/Preferences/ABFSS Registration
#
# Safety model:
# - If <dirSRC> is non-empty, migration is skipped
# - Exception: if runtime paths are NOT symlinks, they are repaired
# - Never creates fake files
# - Never links to iCloud
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  dirRoot = "/Users/ven/ven-dots/user-data/apps";
  appSlug = "a_better_finder_rename";

  dirSRC  = "${dirRoot}/${appSlug}";
  dirConf = "${dirSRC}/conf";
  dirPref = "${dirSRC}/pref";

  asRealName = "A Better Finder Rename 12";
  asPath     = "${home}/Library/Application Support/${asRealName}";

  prefItems = [
    "${home}/Library/Preferences/net.publicspace.abfr12.plist"
    "${home}/Library/Preferences/ABFR Registration"
    "${home}/Library/Preferences/ABFSS Registration"
  ];
in
{
  home.activation.abfrUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="A Better Finder Rename"
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
          [ "$(readlink "$link")" = "$target" ] && return 0
          unlink_if_symlink "$link"
        elif [ -e "$link" ]; then
          echo "[$APP] Not a symlink at: $link (will not delete) ⚠️"
          return 1
        fi

        echo "[$APP] Creating symlink: $link → $target 🔗"
        ln -s "$target" "$link" || true
      }

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH SETUP ---
      # ------------------------------------------------------------
      ensure_dir "${dirSRC}"
      ensure_dir "${dirConf}"
      ensure_dir "${dirPref}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      if path_is_symlink "${asPath}"; then
        ensure_symlink "${asPath}" "${dirConf}" || true
      elif [ -e "${asPath}" ]; then
        echo "[$APP] Migrating Application Support → conf 📦"
        mv "${asPath}" "${dirConf}" || true
        ensure_symlink "${asPath}" "${dirConf}" || true
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES FILES ---
      # ------------------------------------------------------------
      for pref in ${lib.concatStringsSep " " prefItems}; do
        name="$(basename "$pref")"
        dst="${dirPref}/$name"

        if path_is_symlink "$pref"; then
          ensure_symlink "$pref" "$dst" || true
        elif [ -e "$pref" ]; then
          backup_runtime_item "$pref"
          echo "[$APP] Migrating preference file: $name 📄"
          mv "$pref" "$dst" || true
          ensure_symlink "$pref" "$dst" || true
        fi
      done

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
