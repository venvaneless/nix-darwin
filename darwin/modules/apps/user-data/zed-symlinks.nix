# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/zed-symlinks.nix
#
# ZED: USER-DATA MIDDLE-MAN
# ============================================================
# Source of truth:
#     /Users/ven/ven-dots/user-data/apps/zed
#
# Runtime paths:
#     ~/Library/Application Support/Zed
#     ~/Library/Preferences/dev.zed.Zed.plist
#     ~/.config/zed
#
# Responsibilities:
#   - Ensure dotfiles path exists (initialize from system if needed)
#   - Ensure Application Support/Zed is a folder (not a symlink)
#   - Ensure all files inside are symlinks pointing to dotfiles
#   - Move new system-created files back into dotfiles
#   - Ensure plist is symlinked
#   - Ensure ~/.config/zed is moved into dotfiles/apps/zed/user-data
#   - Ensure ~/.config/zed is symlinked back to that source of truth
#   - Never overwrite dotfiles
#   - Never interact with iCloud
#   - Never install or update anything
#   - Never launch Zed
#
# ============================================================

{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;

  # MAIN ZED DOTFILES ROOT
  dotZed = "/Users/ven/ven-dots/user-data/apps/zed";

  # USER-DATA DIRECTORY INSIDE ZED DOTFILES
  dotUser = "${dotZed}/user-data";

  cfgDir = "${home}/.config/zed";  # Runtime location

  asZed    = "${home}/Library/Application Support/Zed";
  plist    = "${home}/Library/Preferences/dev.zed.Zed.plist";
  dotPlist = "${dotZed}/dev.zed.Zed.plist";
in
{
  home.activation.zedUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing Zed user-data..."

      # ------------------------------------------------------------
      # Move ~/.config/zed into dotfiles/apps/zed/user-data
      # ------------------------------------------------------------
      mkdir -p "${dotUser}"

      # MOVE LOGIC:
      # Move only items that do NOT already exist inside the source of truth
      if [ -d "${cfgDir}" ] && [ ! -L "${cfgDir}" ]; then
        echo "Found real ~/.config/zed → migrating missing items into dotfiles/user-data..."

        for item in "${cfgDir}"/*; do
          [ -e "$item" ] || continue
          name="$(basename "$item")"

          # Skip items already present in source of truth
          if [ -e "${dotUser}/$name" ]; then
            echo "  Skipping existing: $name"
            continue
          fi

          echo "  Moving: $name"
          mv "$item" "${dotUser}/$name"
        done
      fi

      # Ensure ~/.config exists
      mkdir -p "${home}/.config"

      # ------------------------------------------------------------
      # Ensure ~/.config/zed is a symlink → dotUser
      # ------------------------------------------------------------
      echo "Ensuring ~/.config/zed is a symlink → ${dotUser}"

      if [ ! -L "${cfgDir}" ] || [ "$(readlink "${cfgDir}")" != "${dotUser}" ]; then
        rm -rf "${cfgDir}"
        ln -sfn "${dotUser}" "${cfgDir}"
        echo "Symlink created: ~/.config/zed → ${dotUser}"
      else
        echo "Symlink already correct."
      fi


      # ------------------------------------------------------------
      # Ensure dotfiles (Zed root) exists. If missing → initialize.
      # ------------------------------------------------------------
      if [ ! -d "${dotZed}" ]; then
        echo "Zed dotfiles missing → creating."
        mkdir -p "${dotZed}"

        # Copy existing Application Support files if they exist
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
      # dotfiles → Application Support symlinks
      # BUT DO NOT SYMLINK user-data INTO APPLICATION SUPPORT
      # ------------------------------------------------------------
      for item in "${dotZed}"/*; do
        name="$(basename "$item")"

        # Skip plist
        [ "$name" = "dev.zed.Zed.plist" ] && continue

        # SKIP THE user-data DIRECTORY
        [ "$name" = "user-data" ] && continue

        ln -sfn "$item" "${asZed}/$name"
      done


      # ------------------------------------------------------------
      # Move system-created new directories → dotfiles (AS only)
      # ------------------------------------------------------------
      while IFS= read -r item; do
        name="$(basename "$item")"

        [ "$name" = "." ] && continue
        [ "$name" = ".." ] && continue
        [ "$name" = "dev.zed.Zed.plist" ] && continue
        [ "$name" = "user-data" ] && continue  # DON'T TOUCH USER CONFIG

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


      # ------------------------------------------------------------
      # Move system-created files → dotfiles (AS only)
      # ------------------------------------------------------------
      while IFS= read -r item; do
        name="$(basename "$item")"

        [ "$name" = "dev.zed.Zed.plist" ] && continue
        [ "$name" = "user-data" ] && continue  # DON'T TOUCH USER CONFIG

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

      echo "Done: Zed"
    '';
}
