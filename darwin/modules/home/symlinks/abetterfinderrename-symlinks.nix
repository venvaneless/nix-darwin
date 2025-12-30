# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/abetterfinderrename-symlinks.nix
#
# DARWIN: A BETTER FINDER RENAME USER-DATA
# ============================================================
# Bulk file renaming utility.
#
# Moves Application Support data into ven-dots as "conf" and symlinks it back.
# Moves Preferences items into ven-dots as "pref" and symlinks them back.
#
# Safety model:
# - Skips migration if source-of-truth root is non-empty
# - Still fixes broken symlinks even when skipping migration
# - Never creates fake preference files
# - Never links to iCloud
# ============================================================

{ config, lib, ... }:

let
  # ------------------------------------------------------------
  # --- PATH DEFINITIONS ---
  # ------------------------------------------------------------
  home = config.home.homeDirectory;

  dirRoot = "/Users/ven/ven-dots/user-data/apps";
  appName = "a_better_finder_rename";
  dirSRC  = "${dirRoot}/${appName}";

  dirConf = "${dirSRC}/conf";
  dirPref = "${dirSRC}/pref";

  asRealName = "A Better Finder Rename 12";
  asPath     = "${home}/Library/Application Support/${asRealName}";

  prefItems = [
    "${home}/Library/Preferences/net.publicspace.abfr12.plist"
    "${home}/Library/Preferences/ABFR Registration"
  ];
in
{
  home.activation.abfrUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      APP="A Better Finder Rename"
      echo "[$APP] User-data sync starting… 🚀"

      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d 📁"
          mkdir -p "$d"
        fi
      }

      dir_is_empty() {
        local d="$1"
        [ -d "$d" ] || return 1
        [ -z "$(ls -A "$d" 2>/dev/null || true)" ]
      }

      safe_unlink_if_symlink() {
        local p="$1"
        [ -L "$p" ] && unlink "$p"
      }

      ensure_symlink() {
        local link="$1"
        local target="$2"

        if [ -L "$link" ]; then
          [ "$(readlink "$link")" = "$target" ] && return 0
          safe_unlink_if_symlink "$link"
        elif [ -e "$link" ]; then
          return 1
        fi

        ln -s "$target" "$link"
      }

      move_with_backup_if_needed() {
        local src="$1"
        local dst="$2"

        if [ -e "$dst" ] && [ ! -L "$dst" ] && ! dir_is_empty "$dst"; then
          ts="$(date +%Y%m%d-%H%M%S)"
          mv "$dst" "${dst}.backup-${ts}"
        fi

        mv "$src" "$dst"
      }

      ensure_dir "${dirSRC}"
      allowMigrate="0"
      dir_is_empty "${dirSRC}" && allowMigrate="1"

      ensure_dir "${dirConf}"
      ensure_dir "${dirPref}"

      if [ -e "${asPath}" ]; then
        if [ "$allowMigrate" = "1" ] && [ ! -L "${asPath}" ]; then
          move_with_backup_if_needed "${asPath}" "${dirConf}"
        fi
        ensure_symlink "${asPath}" "${dirConf}" || true
      fi

      for pref in ${lib.concatStringsSep " " prefItems}; do
        name="$(basename "$pref")"
        dst="${dirPref}/$name"

        if [ -e "$pref" ]; then
          if [ "$allowMigrate" = "1" ] && [ ! -L "$pref" ]; then
            move_with_backup_if_needed "$pref" "$dst"
          fi
          ensure_symlink "$pref" "$dst" || true
        fi
      done

      echo "[$APP] User-data sync complete ✅"
    '';
}
