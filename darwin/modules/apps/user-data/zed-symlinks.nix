# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/zed-symlinks.nix
#
# ZED: USER-DATA MIDDLE-MAN
# ============================================================
# Source of truth:
#     /Users/ven/dotfiles/apps/zed
#
# Runtime paths:
#     ~/Library/Application Support/Zed
#     ~/Library/Preferences/dev.zed.Zed.plist
#     ~/.config/zed   (ADDED)
#
# Responsibilities:
#   - Ensure dotfiles path exists (initialize from system if needed)
#   - Ensure Application Support/Zed is a folder (not a symlink)
#   - Ensure all files inside are symlinks pointing to dotfiles
#   - Move new system-created files back into dotfiles
#   - Ensure plist is symlinked
#   - Ensure ~/.config/zed is symlinked to dotfiles/apps/zed/user-data  (ADDED)
#   - Never overwrite dotfiles
#   - Never interact with iCloud
#   - Never install or update anything
#   - Never launch Zed
#
# This file replaces ALL previous Zed user-data files.
# ============================================================

{ config, lib, pkgs, ... }:

let
  home      = config.home.homeDirectory;
  dotZed    = "/Users/ven/ven-dots/user-data/apps/zed";
  dotUser   = "/Users/ven/ven-dots/user-data/apps/zed/user-data";   # NEW

  cfgDir    = "${home}/.config/zed";                      # NEW

  asZed     = "${home}/Library/Application Support/Zed";
  plist     = "${home}/Library/Preferences/dev.zed.Zed.plist";
  dotPlist  = "${dotZed}/dev.zed.Zed.plist";
in
{
  home.activation.zedUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing Zed user-data..."

      # ------------------------------------------------------------
      # NEW: ~/.config/zed → dotfiles/apps/zed/user-data
      # ------------------------------------------------------------
      mkdir -p "${dotUser}"

      # If ~/.config/zed exists AND is not a symlink → move its content once
      if [ -d "${cfgDir}" ] && [ ! -L "${cfgDir}" ]; then
        echo "Found real ~/.config/zed → moving contents into dotfiles/user-data..."
        for item in "${cfgDir}"/*; do
          name="$(basename "$item")"
          if [ -L "$item" ]; then
            continue
          fi
          echo "  Moving: $name"
          mv "$item" "${dotUser}/$name"
        done
      fi

      # Ensure ~/.config exists
      mkdir -p "${home}/.config"

      # Ensure ~/.config/zed is a symlink pointing to user-data
      if [ ! -L "${cfgDir}" ] || [ "$(readlink "${cfgDir}")" != "${dotUser}" ]; then
        echo "Linking ~/.config/zed → ${dotUser}"
        rm -rf "${cfgDir}"
        ln -sfn "${dotUser}" "${cfgDir}"
      fi


      # ------------------------------------------------------------
      # Ensure dotfiles directory exists. If missing → initialize.
      # ------------------------------------------------------------
      if [ ! -d "${dotZed}" ]; then
        echo "Zed dotfiles missing → creating."
        mkdir -p "${dotZed}"

        # Copy system files if they exist
        if [ -d "${asZed}" ]; then
          echo "Copying existing application support files → dotfiles"
          cp -a "${asZed}/." "${dotZed}/" 2>/dev/null || true
        fi

        if [ -f "${plist}" ]; then
          echo "Copying plist → dotfiles"
          cp -a "${plist}" "${dotPlist}" || true
        fi
      fi


      # ------------------------------------------------------------
      # Ensure Application Support/Zed is a REAL folder
      # ------------------------------------------------------------
      if [ -L "${asZed}" ]; then
        echo "Fixing: Application Support/Zed must not be a symlink."
        rm -f "${asZed}"
      fi

      mkdir -p "${asZed}"


      # ------------------------------------------------------------
      # Ensure dotfiles → system symlinks
      # ------------------------------------------------------------
      for item in "${dotZed}"/*; do
        name="$(basename "$item")"
        [ "$name" = "dev.zed.Zed.plist" ] && continue
        ln -sfn "$item" "${asZed}/$name"
      done


      # ------------------------------------------------------------
      # Move system-created new items → dotfiles (directories first)
      # ------------------------------------------------------------

      # FIRST: move directories only
      while IFS= read -r item; do
        name="$(basename "$item")"

        # Skip . and .. and plist
        [ "$name" = "." ] && continue
        [ "$name" = ".." ] && continue
        [ "$name" = "dev.zed.Zed.plist" ] && continue

        # If dotfiles already has anything with this name → skip moving it
        if [ -e "${dotZed}/$name" ]; then
          echo "Skipping directory $name — already exists in dotfiles."
          rm -rf "$item"
          ln -sfn "${dotZed}/$name" "${asZed}/$name"
          continue
        fi

        echo "Moving new directory to dotfiles: $name"
        mv "$item" "${dotZed}/$name"
        ln -sfn "${dotZed}/$name" "${asZed}/$name"
      done < <(find "${asZed}" -maxdepth 1 -mindepth 1 -type d)


      # SECOND: move files only
      while IFS= read -r item; do
        name="$(basename "$item")"

        # Skip plist
        [ "$name" = "dev.zed.Zed.plist" ] && continue

        # If dotfiles already has anything with this name → skip moving
        if [ -e "${dotZed}/$name" ]; then
          echo "Skipping file $name — already exists in dotfiles."
          rm -f "$item"
          ln -sfn "${dotZed}/$name" "${asZed}/$name"
          continue
        fi

        echo "Moving new file to dotfiles: $name"
        mv "$item" "${dotZed}/$name"
        ln -sfn "${dotZed}/$name" "${asZed}/$name"
      done < <(find "${asZed}" -maxdepth 1 -mindepth 1 -type f)


      # ------------------------------------------------------------
      # Plist handling
      # ------------------------------------------------------------
      mkdir -p "${dotZed}"

      if [ -f "${plist}" ] && [ ! -L "${plist}" ]; then
        echo "Moving real plist → dotfiles"
        mv "${plist}" "${dotPlist}"
      fi

      if [ ! -f "${dotPlist}" ]; then
        : > "${dotPlist}"
      fi

      ln -sfn "${dotPlist}" "${plist}"

      echo "Zed user-data sync complete."
    '';
}
