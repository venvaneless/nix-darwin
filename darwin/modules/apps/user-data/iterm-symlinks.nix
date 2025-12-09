# DARWIN: ITERM USER-DATA (FIXED VERSION)
# ============================================================
# - Move CONTENTS of ~/Library/Application Support/iTerm2 → dotfiles
# - Symlink the iTerm2 folder itself back to dotfiles/apps/iterm
# - Move plist files → dotfiles
# - Symlink plist files back into Preferences
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
      echo "Managing iTerm user-data (fixed)..."

      # ------------------------------------------------------------
      # Ensure dotfiles root exists
      # ------------------------------------------------------------
      mkdir -p "${dotIterm}"

      # ------------------------------------------------------------
      # Move CONTENTS of Application Support/iTerm2 → dotfiles
      # NOT the folder itself.
      # ------------------------------------------------------------
      if [ -d "${asIterm}" ] && [ ! -L "${asIterm}" ]; then
        echo "Migrating iTerm2 contents → dotfiles"

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
      # Replace Application Support/iTerm2 with a symlink
      # ------------------------------------------------------------
      rm -rf "${asIterm}"
      ln -sfn "${dotIterm}" "${asIterm}"
      echo "Symlink created: iTerm2 → ${dotIterm}"

      # ------------------------------------------------------------
      # MAIN PLIST
      # ------------------------------------------------------------
      if [ -f "${sysPlistMain}" ] && [ ! -L "${sysPlistMain}" ] && [ ! -f "${dotPlistMain}" ]; then
        echo "Moving main plist → dotfiles"
        mv "${sysPlistMain}" "${dotPlistMain}"
      fi

      if [ ! -f "${dotPlistMain}" ]; then
        echo "Creating empty main plist"
        : > "${dotPlistMain}"
      fi

      ln -sfn "${dotPlistMain}" "${sysPlistMain}"
      echo "Main plist symlinked."

      # ------------------------------------------------------------
      # PRIVATE PLIST
      # ------------------------------------------------------------
      if [ -f "${sysPlistPrivate}" ] && [ ! -L "${sysPlistPrivate}" ] && [ ! -f "${dotPlistPrivate}" ]; then
        echo "Moving private plist → dotfiles"
        mv "${sysPlistPrivate}" "${dotPlistPrivate}"
      fi

      if [ ! -f "${dotPlistPrivate}" ]; then
        echo "Creating empty private plist"
        : > "${dotPlistPrivate}"
      fi

      ln -sfn "${dotPlistPrivate}" "${sysPlistPrivate}"
      echo "Private plist symlinked."

      echo "iTerm user-data relocation complete."
    '';
}
