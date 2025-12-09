# DARWIN: ITERM USER-DATA + PROFILE SYMLINKING
# ============================================================
# Source of truth:
#     /Users/ven/ven-dots/user-data/apps/iterm
#
# Runtime paths:
#     ~/Library/Application Support/iTerm2
#     ~/Library/Preferences/com.googlecode.iterm2.plist
#     ~/Library/Preferences/com.googlecode.iterm2.private.plist
#
# Responsibilities:
#   - Ensure ven-dots/apps/iterm exists
#   - Move real iTerm2 Application Support into ven-dots if present
#   - Ensure Application Support/iTerm2 is a symlink → ven-dots/apps/iterm
#   - Move both plist files into ven-dots and symlink them back
#   - Never overwrite existing dotfiles copies
#   - Idempotent: safe to run on every activation
# ============================================================

{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;

  dotIterm = "/Users/ven/ven-dots/user-data/apps/iterm";
  asIterm  = "${home}/Library/Application Support/iTerm2";

  sysPlistMain    = "${home}/Library/Preferences/com.googlecode.iterm2.plist";
  sysPlistPrivate = "${home}/Library/Preferences/com.googlecode.iterm2.private.plist";

  dotPlistMain    = "${dotIterm}/com.googlecode.iterm2.plist";
  dotPlistPrivate = "${dotIterm}/com.googlecode.iterm2.private.plist";
in
{
  home.activation.itermUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing iTerm user-data..."

      # ------------------------------------------------------------
      # Ensure dotfiles root exists
      # ------------------------------------------------------------
      if [ ! -d "${dotIterm}" ]; then
        echo "Creating iTerm dotfiles root → ${dotIterm}"
        mkdir -p "${dotIterm}"

        # If Application Support/iTerm2 exists, copy its contents once
        if [ -d "${asIterm}" ] && [ ! -L "${asIterm}" ]; then
          echo "Copying existing Application Support/iTerm2 → dotfiles"
          cp -a "${asIterm}/." "${dotIterm}/" 2>/dev/null || true
        fi

        # Copy plists if they exist
        if [ -f "${sysPlistMain}" ]; then
          echo "Copying existing main plist → dotfiles"
          cp -a "${sysPlistMain}" "${dotPlistMain}" || true
        fi

        if [ -f "${sysPlistPrivate}" ]; then
          echo "Copying existing private plist → dotfiles"
          cp -a "${sysPlistPrivate}" "${dotPlistPrivate}" || true
        fi
      fi

      # ------------------------------------------------------------
      # Ensure Application Support/iTerm2 is a REAL DIR before migration
      # ------------------------------------------------------------
      if [ -L "${asIterm}" ]; then
        echo "Fixing: Application Support/iTerm2 must not be a symlink pre-migration"
        rm -f "${asIterm}"
      fi

      if [ -d "${asIterm}" ]; then
        echo "Found real iTerm2 directory → preparing for migration"
      fi

      # ------------------------------------------------------------
      # Move system-created files/dirs from AS → dotfiles (Chromium-style)
      # ------------------------------------------------------------
      if [ -d "${asIterm}" ] && [ ! -L "${asIterm}" ]; then
        echo "Migrating iTerm2 items into dotfiles..."

        for item in "${asIterm}"/*; do
          [ -e "$item" ] || continue
          name="$(basename "$item")"

          if [ -e "${dotIterm}/$name" ]; then
            echo "  Skipping existing: $name"
            rm -rf "$item"
            ln -sfn "${dotIterm}/$name" "${asIterm}/$name"
            continue
          fi

          echo "  Moving: $name"
          mv "$item" "${dotIterm}/$name"
          ln -sfn "${dotIterm}/$name" "${asIterm}/$name"
        done
      fi

      # ------------------------------------------------------------
      # Recreate Application Support/iTerm2 as a symlink → dotfiles
      # ------------------------------------------------------------
      rm -rf "${asIterm}"
      ln -sfn "${dotIterm}" "${asIterm}"
      echo "Symlink created: iTerm2 → ${dotIterm}"

      # ------------------------------------------------------------
      # PLIST HANDLING (main + private)
      # ------------------------------------------------------------
      echo "Managing iTerm plists..."

      # MAIN PLIST
      if [ -f "${sysPlistMain}" ] && [ ! -L "${sysPlistMain}" ] && [ ! -f "${dotPlistMain}" ]; then
        echo "Moving main plist → dotfiles"
        mv "${sysPlistMain}" "${dotPlistMain}"
      fi

      if [ ! -f "${dotPlistMain}" ]; then
        echo "Creating empty main plist in dotfiles"
        : > "${dotPlistMain}"
      fi

      ln -sfn "${dotPlistMain}" "${sysPlistMain}"
      echo "Main plist symlinked: ${sysPlistMain} → ${dotPlistMain}"

      # PRIVATE PLIST
      if [ -f "${sysPlistPrivate}" ] && [ ! -L "${sysPlistPrivate}" ] && [ ! -f "${dotPlistPrivate}" ]; then
        echo "Moving private plist → dotfiles"
        mv "${sysPlistPrivate}" "${dotPlistPrivate}"
      fi

      if [ ! -f "${dotPlistPrivate}" ]; then
        echo "Creating empty private plist in dotfiles"
        : > "${dotPlistPrivate}"
      fi

      ln -sfn "${dotPlistPrivate}" "${sysPlistPrivate}"
      echo "Private plist symlinked: ${sysPlistPrivate} → ${dotPlistPrivate}"

      echo "iTerm user-data sync complete."
    '';
}
