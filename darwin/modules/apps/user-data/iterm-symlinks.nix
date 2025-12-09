# DARWIN: ITERM USER-DATA (NO PLIST HANDLING)
# ============================================================
# Source of truth:
#     /Users/ven/ven-dots/user-data/apps/iterm
#
# Runtime paths:
#     ~/Library/Application Support/iTerm2
#
# Responsibilities:
#   - Move CONTENTS of App Support/iTerm2 to dotfiles
#   - Symlink iTerm2 folder back to dotfiles path
#   - DO NOT touch plist files at all (iTerm handles them)
# ============================================================

{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;

  dotIterm = "/Users/ven/ven-dots/user-data/apps/iterm";
  asIterm  = "${home}/Library/Application Support/iTerm2";

in
{
  home.activation.itermUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing iTerm user-data (no plist moves)..."

      # ------------------------------------------------------------
      # Ensure dotfiles root exists
      # ------------------------------------------------------------
      mkdir -p "${dotIterm}"

      # ------------------------------------------------------------
      # Move CONTENTS of Application Support/iTerm2 → dotfiles
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
      # Replace the entire iTerm2 folder with a symlink → dotfiles
      # ------------------------------------------------------------
      rm -rf "${asIterm}"
      ln -sfn "${dotIterm}" "${asIterm}"
      echo "Symlink created: iTerm2 → ${dotIterm}"

      echo "iTerm Application Support relocation complete (plists untouched)."
    '';
}
