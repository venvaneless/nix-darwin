# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/masscode-symlinks.nix
#
# DARWIN: MASSCODE USER-DATA
# ============================================================
# massCode snippet manager.
#
# Source of truth:
# - Application Support content lives in:  <dirSRC>/conf
# - Preferences content lives in:          <dirSRC>
#
# Runtime paths:
# - ~/Library/Application Support/masscode
# - ~/Library/Preferences/io.masscode.app.plist
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
  appSlug = "masscode";

  dirSRC  = "${dirRoot}/${appSlug}";
  dirConf = "${dirSRC}/conf";

  asRealName = "masscode";
  asPath     = "${home}/Library/Application Support/${asRealName}";

  prefItems = [
    "${home}/Library/Preferences/io.masscode.app.plist"
  ];
in
{
  home.activation.masscodeUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="massCode"
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

      backup_dest_if_needed() {
        local dst="$1"

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
          if [ -d "$dst" ] && dir_is_empty "$dst"; then
            echo "[$APP] Destination exists but empty. Removing: $dst 🧹"
            rmdir "$dst" 2>/dev/null || true
            return 0
          fi

          local ts backup
          ts="$(date +%Y%m%d-%H%M%S)"
          backup="$dst.backup-$ts"

          echo "[$APP] Destination collision. Backing up: $dst → $backup 📦"
          mv "$dst" "$backup" || true
        fi
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
      ensure_dir "${dirConf}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT ---
      # ------------------------------------------------------------
      # GOAL:
      # - Source-of-truth path MUST be: ${dirConf}
      # - Runtime folder name MUST stay: ${asPath}
      # - NEVER create nested: ${dirConf}/${asRealName}
      #
      # FIX:
      # - If migrating, rename the runtime folder INTO ${dirConf}
      #   (requires removing empty ${dirConf} first)
      # ------------------------------------------------------------
      if path_is_symlink "${asPath}"; then
        echo "[$APP] Application Support is a symlink. Verifying… 🔎"
        ensure_symlink "${asPath}" "${dirConf}" || true
      elif [ -e "${asPath}" ]; then
        if dir_is_empty "${dirConf}"; then
          echo "[$APP] Migrating Application Support → conf 📦"

          # If conf/ exists (created earlier) and is empty, remove it so mv renames correctly.
          rmdir "${dirConf}" 2>/dev/null || true

          # Rename: <runtime folder> -> <dirConf>
          mv "${asPath}" "${dirConf}" || true
        else
          echo "[$APP] conf already populated. Skipping migration (will not overwrite) ⚠️"
          backup_runtime_item "${asPath}"
        fi

        ensure_symlink "${asPath}" "${dirConf}" || true
      else
        echo "[$APP] Application Support missing. Creating symlink 🔗"
        ensure_symlink "${asPath}" "${dirConf}" || true
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES FILE ---
      # ------------------------------------------------------------
      # RULE:
      # - Move runtime file -> ${dirSRC}/<name>
      # - THEN symlink back to runtime path
      #
      # IMPORTANT:
      # - Do NOT "backup runtime" BEFORE migration (that deletes the source)
      # - Backup destination only (if it exists and would be overwritten)
      # ------------------------------------------------------------
      for pref in ${lib.concatStringsSep " " prefItems}; do
        name="$(basename "$pref")"
        dst="${dirSRC}/$name"

        if path_is_symlink "$pref"; then
          echo "[$APP] Preferences item is a symlink. Verifying: $pref 🔎"
          ensure_symlink "$pref" "$dst" || true
          continue
        fi

        if [ -e "$pref" ]; then
          if [ -e "$dst" ]; then
            echo "[$APP] Destination exists; repairing runtime into symlink: $name 🔧"
            backup_runtime_item "$pref"
          else
            echo "[$APP] Migrating preference file: $name 📄"
            backup_dest_if_needed "$dst"
            mv "$pref" "$dst" || true
          fi

          ensure_symlink "$pref" "$dst" || true
        else
          echo "[$APP] Preferences item missing. Skipping: $pref ✅"
        fi
      done

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
