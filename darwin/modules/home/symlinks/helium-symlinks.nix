# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/helium-symlinks.nix
#
# DARWIN: HELIUM USER-DATA
# =========================
# Helium user-data management.
#
# Source of truth:
# - Application Support directory is moved to:  <dirSRC>
# - Preferences plist is moved to:              <dirSRC>/net.imput.helium.plist
#
# Runtime paths:
# - ~/Library/Application Support/net.imput.helium
# - ~/Library/Preferences/net.imput.helium.plist
#
# Final layout:
# - /Users/ven/ven-dots/user-data/apps/helium
#     - Default/
#     - ...
#     - net.imput.helium.plist
#
# Symlinks:
# - ~/Library/Application Support/net.imput.helium
#     -> /Users/ven/ven-dots/user-data/apps/helium
# - ~/Library/Preferences/net.imput.helium.plist
#     -> /Users/ven/ven-dots/user-data/apps/helium/net.imput.helium.plist
# =========================

{ config, lib, ... }:

let
  # DARWIN: PATHS
  # =========================
  home = config.home.homeDirectory;

  # Root for app data
  dirRoot = "/Users/ven/ven-dots/user-data/apps";

  # App label
  appName = "Helium";

  # Source-of-truth directory name inside apps/
  appSlug = "helium";

  # Final source-of-truth directory
  dirSRC = "${dirRoot}/${appSlug}";

  # Original runtime directory used by Helium
  asPath = "${home}/Library/Application Support/net.imput.helium";

  # Preferences plist
  prefPlist = "${home}/Library/Preferences/net.imput.helium.plist";
  dotPlist  = "${dirSRC}/net.imput.helium.plist";
in
{
  home.activation.heliumUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # DARWIN: START LOG
      # =========================
      APP="${appName}"
      echo "[$APP] User-data sync starting..."

      # DARWIN: HELPERS
      # =========================
      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d"
          mkdir -p "$d"
        fi
      }

      dir_is_empty() {
        local d="$1"
        [ -d "$d" ] || return 1
        [ -z "$(ls -A "$d" 2>/dev/null || true)" ]
      }

      unlink_if_symlink() {
        local p="$1"
        if [ -L "$p" ]; then
          echo "[$APP] Removing symlink: $p"
          unlink "$p"
        fi
      }

      backup_dest_if_needed() {
        local dst="$1"

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
          if [ -d "$dst" ] && dir_is_empty "$dst"; then
            rmdir "$dst" || true
            return 0
          fi

          local ts
          ts="$(date +%Y%m%d-%H%M%S)"
          local backup
          backup="$dst.backup-$ts"

          echo "[$APP] Destination collision. Backing up: $dst -> $backup"
          mv "$dst" "$backup"
        fi
      }

      move_with_backup() {
        local src="$1"
        local dst="$2"

        backup_dest_if_needed "$dst"
        echo "[$APP] Moving: $src -> $dst"
        mv "$src" "$dst"
      }

      # DARWIN: ROOT SETUP
      # =========================
      ensure_dir "${dirRoot}"

      allowMigrate="0"
      if [ ! -e "${dirSRC}" ]; then
        echo "[$APP] Source-of-truth does not exist yet. Migration allowed"
        allowMigrate="1"
      elif [ -d "${dirSRC}" ] && dir_is_empty "${dirSRC}"; then
        echo "[$APP] Source-of-truth exists but is empty. Migration allowed"
        allowMigrate="1"
      else
        echo "[$APP] Source-of-truth is not empty. Migration skipped (repair still allowed)"
      fi

      # DARWIN: APPLICATION SUPPORT MOVE
      # Move:
      #   ~/Library/Application Support/net.imput.helium
      # to:
      #   /Users/ven/ven-dots/user-data/apps/helium
      # Then symlink runtime path back to it.
      # =========================
      if [ -e "${asPath}" ]; then
        if [ -L "${asPath}" ]; then
          echo "[$APP] Runtime Application Support is already a symlink. Repairing..."
          unlink_if_symlink "${asPath}"
        else
          if [ "$allowMigrate" = "1" ]; then
            echo "[$APP] Moving runtime folder -> ${dirSRC}"
            move_with_backup "${asPath}" "${dirSRC}"
          else
            echo "[$APP] Runtime folder exists but migration skipped"
          fi
        fi
      fi

      ln -sfn "${dirSRC}" "${asPath}"
      echo "[$APP] Application Support symlinked -> ${dirSRC}"

      # DARWIN: PREFERENCES MOVE
      # Move:
      #   ~/Library/Preferences/net.imput.helium.plist
      # to:
      #   /Users/ven/ven-dots/user-data/apps/helium/net.imput.helium.plist
      # Then symlink runtime plist back to it.
      # =========================
      if [ -e "${prefPlist}" ]; then
        if [ -L "${prefPlist}" ]; then
          echo "[$APP] Preferences plist is already a symlink. Repairing..."
          unlink_if_symlink "${prefPlist}"
        else
          if [ ! -e "${dotPlist}" ]; then
            echo "[$APP] Moving plist -> ${dotPlist}"
            mv "${prefPlist}" "${dotPlist}"
          else
            echo "[$APP] Source plist already exists. Leaving runtime plist in place"
          fi
        fi
      fi

      ln -sfn "${dotPlist}" "${prefPlist}"
      echo "[$APP] Preferences plist symlinked -> ${dotPlist}"

      # DARWIN: END LOG
      # =========================
      echo "[$APP] User-data sync complete"
    '';
}
