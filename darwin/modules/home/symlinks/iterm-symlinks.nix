# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/iterm-symlinks.nix
#
# DARWIN: ITERM USER-DATA (FINAL)
# ============================================================
# iTerm2 user-data relocation with a single source of truth.
#
# Model:
# This module moves the ENTIRE iTerm2 Application Support folder
# into ven-dots and symlinks it back under its ORIGINAL NAME.
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/iterm/app_support
#
# Runtime path (unchanged for the app):
#   ~/Library/Application Support/iTerm2
#
# Preferences:
#   ~/Library/Preferences/com.googlecode.iterm2.plist
#   ~/Library/Preferences/com.googlecode.iterm2.private.plist
#
# Preferences source of truth:
#   /Users/ven/ven-dots/user-data/apps/iterm/pref
#
# Rules:
# - Folder names NEVER change
# - No empty files are ever created (missing plist = skip)
# - Plists are MOVED first, then symlinked back
# - No partial migrations
# - If something already exists, it is reused
# ============================================================

{ config, lib, ... }:

let
  home = config.home.homeDirectory;

  # ------------------------------------------------------------
  # SOURCE OF TRUTH (APP ROOT)
  # ------------------------------------------------------------
  appRoot = "/Users/ven/ven-dots/user-data/apps/iterm";

  # Application Support source of truth
  dotAppSupport = "${appRoot}/app_support";

  # Preferences source of truth
  dotPref = "${appRoot}/pref";

  # ------------------------------------------------------------
  # RUNTIME PATHS (MUST KEEP ORIGINAL NAMES)
  # ------------------------------------------------------------
  asPath = "${home}/Library/Application Support/iTerm2";

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
      if [ ! -d "${appRoot}" ]; then
        echo "[$APP] Creating app root: ${appRoot} 📁"
        mkdir -p "${appRoot}"
      fi

      if [ ! -d "${dotAppSupport}" ]; then
        echo "[$APP] Creating Application Support source-of-truth: ${dotAppSupport} 📁"
        mkdir -p "${dotAppSupport}"
      fi

      if [ ! -d "${dotPref}" ]; then
        echo "[$APP] Creating Preferences source-of-truth: ${dotPref} 📁"
        mkdir -p "${dotPref}"
      fi

      # ------------------------------------------------------------
      # APPLICATION SUPPORT (WHOLE FOLDER)
      # ------------------------------------------------------------
      # Goal:
      # - Move:   ~/Library/Application Support/iTerm2
      # - To:     ${dotAppSupport}
      # - Then:   symlink ~/Library/Application Support/iTerm2 -> ${dotAppSupport}
      #
      # Runtime folder name MUST remain: iTerm2
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        if [ -z "$(ls -A "${dotAppSupport}")" ]; then
          echo "[$APP] Moving iTerm2 Application Support → ${dotAppSupport} 📦"
          rmdir "${dotAppSupport}" 2>/dev/null || true
          mv "${asPath}" "${dotAppSupport}"
          echo "[$APP] Move complete: ${asPath} → ${dotAppSupport} ✅"
        else
          echo "[$APP] Source-of-truth not empty. Skipping move ⚠️"
        fi
      fi

      # If runtime path is a symlink, ensure it points to dotAppSupport
      if [ -L "${asPath}" ]; then
        current="$(readlink "${asPath}")"
        if [ "$current" != "${dotAppSupport}" ]; then
          echo "[$APP] Fixing Application Support symlink 🔧"
          unlink "${asPath}"
          echo "[$APP] Removed wrong symlink: ${asPath} 🧹"
        fi
      fi

      # If runtime path doesn't exist, create the correct symlink
      if [ ! -e "${asPath}" ]; then
        echo "[$APP] Symlinking Application Support → ${dotAppSupport} 🔗"
        ln -s "${dotAppSupport}" "${asPath}"
        echo "[$APP] Symlink created: ${asPath} → ${dotAppSupport} ✅"
      fi

      # ------------------------------------------------------------
      # PREFERENCES PLISTS
      # ------------------------------------------------------------
      # Rules:
      # - If plist exists (and is NOT a symlink) -> MOVE to dotPref
      # - Then symlink it back
      # - If plist missing -> SKIP (no empty file creation, ever)
      for pref in "${plistMain}" "${plistPrivate}"; do
        name="$(basename "$pref")"
        dst="${dotPref}/${name}"

        if [ -e "$pref" ]; then
          if [ -L "$pref" ]; then
            echo "[$APP] Preferences plist already symlinked. Skipping move: $pref 🔎"
          else
            if [ ! -e "$dst" ]; then
              echo "[$APP] Moving plist → ${dst} 📄"
              mv "$pref" "$dst"
              echo "[$APP] Move complete: $pref → $dst ✅"
            else
              echo "[$APP] Destination plist already exists. Skipping move ⚠️"
            fi
          fi

          if [ -e "$dst" ] && [ ! -L "$pref" ]; then
            echo "[$APP] Symlinking plist → ${dst} 🔗"
            ln -s "$dst" "$pref"
            echo "[$APP] '$name' is being symlinked back to Preferences 🔗"
          fi
        else
          echo "[$APP] Preferences plist missing. Skipping: $pref ✅"
        fi
      done

      echo "[$APP] User-data sync complete ✅"
    '';
}
