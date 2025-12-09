# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/iterm-symlinks.nix
# 
# DARWIN: ITERM USER-DATA + PLIST SYMLINKING
# ============================================================
# Source of truth:
#     /Users/ven/ven-dots/user-data/apps/iterm
#
# Runtime paths:
#     ~/Library/Preferences/com.googlecode.iterm2.plist
#     ~/Library/Preferences/com.googlecode.iterm2.private.plist
#
# Responsibilities:
#   - Ensure ven-dots/apps/iterm exists
#   - Move real plist files into dotfiles (only once)
#   - Symlink both plist files back to ~/Library/Preferences
#   - Ensure no overwriting of existing dotfiles copies
#   - Maintain complete reproducibility of iTerm configuration
# ============================================================

{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;

  dotIterm = "/Users/ven/ven-dots/user-data/apps/iterm";
  sysPlistMain = "${home}/Library/Preferences/com.googlecode.iterm2.plist";
  sysPlistPrivate = "${home}/Library/Preferences/com.googlecode.iterm2.private.plist";

  dotPlistMain = "${dotIterm}/com.googlecode.iterm2.plist";
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
      fi

      # ------------------------------------------------------------
      # MAIN PLIST MIGRATION
      # ------------------------------------------------------------
      if [ -f "${sysPlistMain}" ] && [ ! -L "${sysPlistMain}" ] && [ ! -f "${dotPlistMain}" ]; then
        echo "Moving main plist → dotfiles"
        mv "${sysPlistMain}" "${dotPlistMain}"
      fi

      if [ ! -f "${dotPlistMain}" ]; then
        echo "Creating empty main plist → dotfiles"
        : > "${dotPlistMain}"
      fi

      ln -sfn "${dotPlistMain}" "${sysPlistMain}"
      echo "Main plist symlinked: ${sysPlistMain} → ${dotPlistMain}"

      # ------------------------------------------------------------
      # PRIVATE PLIST MIGRATION
      # ------------------------------------------------------------
      if [ -f "${sysPlistPrivate}" ] && [ ! -L "${sysPlistPrivate}" ] && [ ! -f "${dotPlistPrivate}" ]; then
        echo "Moving private plist → dotfiles"
        mv "${sysPlistPrivate}" "${dotPlistPrivate}"
      fi

      if [ ! -f "${dotPlistPrivate}" ]; then
        echo "Creating empty private plist → dotfiles"
        : > "${dotPlistPrivate}"
      fi

      ln -sfn "${dotPlistPrivate}" "${sysPlistPrivate}"
      echo "Private plist symlinked: ${sysPlistPrivate} → ${dotPlistPrivate}"

      echo "iTerm user-data sync complete."
    '';
}
