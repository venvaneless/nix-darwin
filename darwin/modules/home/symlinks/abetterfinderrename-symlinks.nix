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
  # --- PATHS ---
  # ------------------------------------------------------------
  home = config.home.homeDirectory;

  dotsApps = "/Users/ven/ven-dots/user-data/apps";
  appFolder = "a_better_finder_rename";

  dotRoot = "${dotsApps}/${appFolder}";
  dotConf = "${dotRoot}/conf";
  dotPref = "${dotRoot}/pref";

  asRealName = "A Better Finder Rename 12";
  asPath = "${home}/Library/Application Support/${asRealName}";

  prefItems = [
    "${home}/Library/Preferences/net.publicspace.abfr12.plist"
    "${home}/Library/Preferences/ABFR Registration"
  ];
in
{
  home.activation.abfrUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- LOGGING SETUP ---
      # ------------------------------------------------------------
      APP="A Better Finder Rename"
      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # --- HELPERS ---
      # ------------------------------------------------------------
      is_symlink() {
        [ -L "$1" ]
      }

      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d 📁"
          mkdir -p "$d"
        else
          echo "[$APP] Directory exists: $d ✅"
        fi
      }

      dir_is_empty() {
        local d="$1"
        [ -d "$d" ] || return 1
        [ -z "$(ls -A "$d" 2>/dev/null || true)" ]
      }

      safe_unlink_if_symlink() {
        local p="$1"
        if [ -L "$p" ]; then
          echo "[$APP] Removing existing symlink: $p 🧹"
          unlink "$p"
        fi
      }

      ensure_symlink() {
        local linkPath="$1"
        local targetPath="$2"

        if [ -L "$linkPath" ]; then
          local currentTarget
          currentTarget="$(readlink "$linkPath" || true)"

          if [ "$currentTarget" = "$targetPath" ]; then
            echo "[$APP] Symlink OK: $linkPath → $targetPath ✅"
            return 0
          fi

          echo "[$APP] Symlink wrong: $linkPath → $currentTarget (expected $targetPath) ⚠️"
          echo "[$APP] Fixing symlink: $linkPath → $targetPath 🔧"
          safe_unlink_if_symlink "$linkPath"
          ln -s "$targetPath" "$linkPath"
          echo "[$APP] Symlink fixed: $linkPath → $targetPath ✅"
          return 0
        fi

        if [ -e "$linkPath" ]; then
          echo "[$APP] Not a symlink at: $linkPath (will not delete automatically) ⚠️"
          return 1
        fi

        echo "[$APP] Creating symlink: $linkPath → $targetPath 🔗"
        ln -s "$targetPath" "$linkPath"
        echo "[$APP] Symlink created: $linkPath → $targetPath ✅"
      }

      move_to_target_with_backup_if_needed() {
        local src="$1"
        local dst="$2"

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
          if [ -d "$dst" ]; then
            if ! dir_is_empty "$dst"; then
              local ts
              ts="$(date +%Y%m%d-%H%M%S)"
              local backup="${dst}.backup-${ts}"
              echo "[$APP] Destination exists and non-empty. Backing up: $dst → $backup 📦"
              mv "$dst" "$backup"
              echo "[$APP] Backup complete: $backup ✅"
            else
              echo "[$APP] Destination exists but empty. Removing empty dir: $dst 🧹"
              rmdir "$dst" || true
            fi
          else
            local ts
            ts="$(date +%Y%m%d-%H%M%S)"
            local backup="${dst}.backup-${ts}"
            echo "[$APP] Destination exists (file). Backing up: $dst → $backup 📦"
            mv "$dst" "$backup"
            echo "[$APP] Backup complete: $backup ✅"
          fi
        fi

        echo "[$APP] Moving: $src → $dst 📦"
        mv "$src" "$dst"
        echo "[$APP] Move complete: $src → $dst ✅"
      }

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH ROOT GUARD ---
      # ------------------------------------------------------------
      if [ ! -d "${dotRoot}" ]; then
        echo "[$APP] Source-of-truth root missing. Creating: ${dotRoot} 📁"
        mkdir -p "${dotRoot}"
      else
        echo "[$APP] Source-of-truth root exists: ${dotRoot} ✅"
      fi

      allowMigrate="0"
      if dir_is_empty "${dotRoot}"; then
        echo "[$APP] Source-of-truth root is empty. Migration allowed ✅"
        allowMigrate="1"
      else
        echo "[$APP] Source-of-truth root is not empty. Migration skipped ⚠️"
        allowMigrate="0"
      fi

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH SUBDIRS ---
      # ------------------------------------------------------------
      ensure_dir "${dotConf}"
      ensure_dir "${dotPref}"

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT: MOVE + SYMLINK ---
      # ------------------------------------------------------------
      if [ -e "${asPath}" ]; then
        if [ -L "${asPath}" ]; then
          echo "[$APP] Application Support is a symlink. Verifying target… 🔎"
          ensure_symlink "${asPath}" "${dotConf}" || true
        else
          if [ "$allowMigrate" = "1" ]; then
            echo "[$APP] '${asRealName}' is being moved from Application Support → ${dotConf} 📦"
            move_to_target_with_backup_if_needed "${asPath}" "${dotConf}"

            echo "[$APP] '${asRealName}' is being symlinked back to Application Support 🔗"
            ensure_symlink "${asPath}" "${dotConf}" || {
              echo "[$APP] ERROR: Could not create symlink at Application Support (path exists and is not a symlink) ⛔"
            }
          else
            echo "[$APP] Application Support exists and is not a symlink, but migration is skipped ⚠️"
            echo "[$APP] Leaving Application Support untouched: ${asPath} ✅"
          fi
        fi
      else
        echo "[$APP] No Application Support data found. Skipping Application Support section ✅"
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES: MOVE + SYMLINK ---
      # ------------------------------------------------------------
      for pref in ${lib.concatStringsSep " " prefItems}; do
        name="$(basename "$pref")"
        dst="${dotPref}/$name"

        if [ -e "$pref" ]; then
          if [ -L "$pref" ]; then
            echo "[$APP] Preferences item is a symlink. Verifying: $pref 🔎"
            ensure_symlink "$pref" "$dst" || true
          else
            echo "[$APP] Preferences item is NOT a symlink. Ensuring it is moved + linked: $pref ⚠️"

            if [ -e "$dst" ] && [ ! -L "$dst" ]; then
              if [ -d "$dst" ] && ! dir_is_empty "$dst"; then
                ts="$(date +%Y%m%d-%H%M%S)"
                backup="${dst}.backup-${ts}"
                echo "[$APP] Destination collision. Backing up: $dst → $backup 📦"
                mv "$dst" "$backup"
                echo "[$APP] Backup complete: $backup ✅"
              elif [ -d "$dst" ]; then
                echo "[$APP] Destination dir exists but empty. Removing empty dir: $dst 🧹"
                rmdir "$dst" || true
              else
                ts="$(date +%Y%m%d-%H%M%S)"
                backup="${dst}.backup-${ts}"
                echo "[$APP] Destination file collision. Backing up: $dst → $backup 📦"
                mv "$dst" "$backup"
                echo "[$APP] Backup complete: $backup ✅"
              fi
            fi

            echo "[$APP] '$name' is being moved from Preferences → ${dotPref} 📄"
            mv "$pref" "$dst"
            echo "[$APP] '$name' has been successfully moved from $pref to $dst ✅"

            echo "[$APP] '$name' is being symlinked back to Preferences 🔗"
            ensure_symlink "$pref" "$dst" || {
              echo "[$APP] ERROR: Could not create symlink in Preferences (path exists and is not a symlink) ⛔"
            }
          fi
        else
          echo "[$APP] Preferences item missing. Skipping: $pref ✅"
        fi
      done

      echo "[$APP] User-data sync complete ✅"
    '';
}
