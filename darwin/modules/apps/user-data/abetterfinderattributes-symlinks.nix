# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/a-better-finder-attributes-symlinks.nix
#
# DARWIN: A BETTER FINDER ATTRIBUTES USER-DATA
# ============================================================
# A Better Finder Attributes is a bulk file attribute editor.
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/a_better_finder_attributes
#
# Runtime locations:
#   ~/Library/Application Support/A Better Finder Attributes
#   ~/Library/Preferences/com.publicspace.abfa.plist
#   ~/Library/Preferences/net.publicspace.abfa7.plist
#
# Responsibilities:
#   - Ensure dotfiles folder exists
#   - Move Application Support contents into dotfiles
#   - Move Preferences plists into dotfiles
#   - Recreate original locations
#   - Symlink files back to original paths
#
# IMPORTANT:
#   - No symlinks are ever created inside the dotfiles folder
#   - Only individual files are symlinked (never whole directories)
# ============================================================

{ config, lib, ... }:

let
  # ------------------------------------------------------------
  # PATH ROOTS
  # ------------------------------------------------------------
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  # ------------------------------------------------------------
  # APP IDENTIFIERS
  # ------------------------------------------------------------
  appFolder = "a_better_finder_attributes";
  asDirName = "A Better Finder Attributes";

  # ------------------------------------------------------------
  # RUNTIME PATHS
  # ------------------------------------------------------------
  asPath      = "${home}/Library/Application Support/${asDirName}";
  prefPlistA  = "${home}/Library/Preferences/com.publicspace.abfa.plist";
  prefPlistB  = "${home}/Library/Preferences/net.publicspace.abfa7.plist";

  # ------------------------------------------------------------
  # DOTFILES PATHS
  # ------------------------------------------------------------
  dotRoot     = "${dotsApp}/${appFolder}";
  dotPlistA   = "${dotRoot}/com.publicspace.abfa.plist";
  dotPlistB   = "${dotRoot}/net.publicspace.abfa7.plist";
in
{
  home.activation.abfaUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: A Better Finder Attributes"

      # DOTFILES
      mkdir -p "${dotRoot}"

      # APPLICATION SUPPORT → DOTFILES
      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        for item in "${asPath}"/*; do
          [ -e "$item" ] || continue
          name="$(basename "$item")"
          [ -e "${dotRoot}/$name" ] || mv "$item" "${dotRoot}/$name"
        done
      fi
      mkdir -p "${asPath}"

      # SYMLINK BACK (FILES ONLY)
      for item in "${dotRoot}"/*; do
        name="$(basename "$item")"
        case "$name" in *.plist) continue ;; esac
        ln -sfn "$item" "${asPath}/$name"
      done

      # PREFERENCES
      [ -f "${prefPlistA}" ] && [ ! -f "${dotPlistA}" ] && mv "${prefPlistA}" "${dotPlistA}"
      [ -f "${prefPlistB}" ] && [ ! -f "${dotPlistB}" ] && mv "${prefPlistB}" "${dotPlistB}"

      [ -f "${dotPlistA}" ] || : > "${dotPlistA}"
      [ -f "${dotPlistB}" ] || : > "${dotPlistB}"

      ln -sfn "${dotPlistA}" "${prefPlistA}"
      ln -sfn "${dotPlistB}" "${prefPlistB}"

      echo "Done: A Better Finder Attributes"
    '';
}
