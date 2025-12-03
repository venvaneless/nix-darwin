# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/chromium-symlinks2.nix
#
# CHROMIUM: USER-DATA MIDDLE-MAN
# ============================================================
# Source of truth:
#     /Users/ven/dotfiles/apps/chromium
#
# Runtime paths:
#     ~/Library/Application Support/Chromium
#     ~/Library/Preferences/org.chromium.Chromium.plist
#
# Responsibilities:
#   - Ensure dotfiles path exists (initialize from system if needed)
#   - Ensure Application Support/Chromium is a folder (not a symlink)
#   - Ensure all files inside are symlinks pointing to dotfiles
#   - Move new system-created files back into dotfiles
#   - Ensure plist is symlinked
#   - Never overwrite dotfiles
#   - Never interact with iCloud
#   - Never install or update anything
#   - Never launch Chromium
#   - SPECIAL: Never move/symlink fragile login DB files:
#       Cookies
#       Cookies-journal
#       Network Persistent State
#       Secure Preferences
#       TransportSecurity
#
# This file mirrors the behavior of the Zed user-data module, but is
# tailored for Chromium’s profile layout. The authoritative copy of
# your browser settings resides under dotfiles/apps/chromium, and new
# files are pulled back from Application Support into dotfiles and
# symlinked. Fragile login-related databases are left as real files
# so Chromium does not lose sessions/logins.
# ============================================================

{ config, lib, pkgs, ... }:

let
  home        = config.home.homeDirectory;
  dotChromium = "/Users/ven/dotfiles/apps/chromium";

  asChromium  = "${home}/Library/Application Support/Chromium";
  plist       = "${home}/Library/Preferences/org.chromium.Chromium.plist";
  dotPlist    = "${dotChromium}/org.chromium.Chromium.plist";
in
{
  home.activation.chromiumUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing Chromium user-data..."

      # ------------------------------------------------------------
      # Fragile DB list: never move/symlink/delete these
      # ------------------------------------------------------------
      fragile_files='
Cookies
Cookies-journal
Network Persistent State
Secure Preferences
TransportSecurity
'

      # NOTE:
      # The previous implementation used a pipeline with "while read"
      # which ran in a subshell and ALWAYS returned 1.
      # This version uses a simple case/esac, so it works correctly.
      is_fragile() {
        case "$1" in
          "Cookies" | \
          "Cookies-journal" | \
          "Network Persistent State" | \
          "Secure Preferences" | \
          "TransportSecurity")
            return 0
            ;;
        esac
        return 1
      }

      # ------------------------------------------------------------
      # Ensure dotfiles directory exists. If missing → initialize.
      # ------------------------------------------------------------
      if [ ! -d "${dotChromium}" ]; then
        echo "Chromium dotfiles missing → creating."
        mkdir -p "${dotChromium}"

        # Copy existing Application Support files into dotfiles once
        if [ -d "${asChromium}" ]; then
          echo "Copying existing Application Support files → dotfiles"
          cp -a "${asChromium}/." "${dotChromium}/" 2>/dev/null || true
        fi

        # Copy plist into dotfiles once
        if [ -f "${plist}" ]; then
          echo "Copying plist → dotfiles"
          cp -a "${plist}" "${dotPlist}" || true
        fi
      fi

      # ------------------------------------------------------------
      # Ensure Application Support/Chromium is a REAL folder
      # ------------------------------------------------------------
      if [ -L "${asChromium}" ]; then
        echo "Fixing: Application Support/Chromium must not be a symlink."
        rm -f "${asChromium}"
      fi

      mkdir -p "${asChromium}"

      # ------------------------------------------------------------
      # Ensure dotfiles → system symlinks (except plist + fragile DBs)
      # ------------------------------------------------------------
      for item in "${dotChromium}"/*; do
        name="$(basename "$item")"

        # Skip plist
        [ "$name" = "org.chromium.Chromium.plist" ] && continue

        # Skip fragile login-related files
        if is_fragile "$name"; then
          echo "Skipping fragile (real file only, no symlink): $name"
          continue
        fi

        ln -sfn "$item" "${asChromium}/$name"
      done

      # ------------------------------------------------------------
      # Move system-created new directories → dotfiles (then symlink)
      # ------------------------------------------------------------
      while IFS= read -r item; do
        name="$(basename "$item")"

        # Skip special/fragile names
        [ "$name" = "." ] && continue
        [ "$name" = ".." ] && continue
        [ "$name" = "org.chromium.Chromium.plist" ] && continue
        if is_fragile "$name"; then
          echo "Leaving fragile directory as real: $name"
          continue
        fi

        if [ -e "${dotChromium}/$name" ]; then
          echo "Linking existing directory from dotfiles: $name"
          rm -rf "$item"
          ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
          continue
        fi

        echo "Moving new directory to dotfiles: $name"
        mv "$item" "${dotChromium}/$name"
        ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
      done < <(find "${asChromium}" -maxdepth 1 -mindepth 1 -type d)

      # ------------------------------------------------------------
      # Move system-created new files → dotfiles (then symlink)
      # ------------------------------------------------------------
      while IFS= read -r item; do
        name="$(basename "$item")"

        # Skip plist
        [ "$name" = "org.chromium.Chromium.plist" ] && continue

        # Skip fragile login-related files
        if is_fragile "$name"; then
          echo "Leaving fragile file as real: $name"
          continue
        fi

        if [ -e "${dotChromium}/$name" ]; then
          echo "Linking existing file from dotfiles: $name"
          rm -f "$item"
          ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
          continue
        fi

        echo "Moving new file to dotfiles: $name"
        mv "$item" "${dotChromium}/$name"
        ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
      done < <(find "${asChromium}" -maxdepth 1 -mindepth 1 -type f)

      # ------------------------------------------------------------
      # Plist handling
      # ------------------------------------------------------------
      mkdir -p "${dotChromium}"

      if [ -f "${plist}" ] && [ ! -L "${plist}" ]; then
        echo "Moving real plist → dotfiles"
        mv "${plist}" "${dotPlist}"
      fi

      if [ ! -f "${dotPlist}" ]; then
        : > "${dotPlist}"
      fi

      ln -sfn "${dotPlist}" "${plist}"

      echo "Chromium user-data sync complete."
    '';
}
