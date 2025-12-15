# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/abetterfinderattributes-symlinks.nix
#
# A BETTER FINDER ATTRIBUTES USER-DATA
# ============================================================
# A Better Finder Attributes is a bulk file attribute editor for macOS.
#
# Moves app state into ven-dots and symlinks it back:
# - Application Support directory
# - Preferences plists (multiple)
#
# Source of truth:
# /Users/ven/ven-dots/user-data/apps/a_better_finder_attributes
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
  asName    = "A Better Finder Attributes";

  # ------------------------------------------------------------
  # RUNTIME PATHS
  # ------------------------------------------------------------
  asPath     = "${home}/Library/Application Support/${asName}";
  prefPlistA = "${home}/Library/Preferences/com.publicspace.abfa.plist";
  prefPlistB = "${home}/Library/Preferences/net.publicspace.abfa7.plist";

  # ------------------------------------------------------------
  # DOTFILES PATHS
  # ------------------------------------------------------------
  dotRoot    = "${dotsApp}/${appFolder}";
  dotAsDir   = "${dotRoot}/Application Support";
  dotPlistA  = "${dotRoot}/com.publicspace.abfa.plist";
  dotPlistB  = "${dotRoot}/net.publicspace.abfa7.plist";
in
{
  home.activation.abfaUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: ${asName}"

      # ------------------------------------------------------------
      # DOTFILES ROOT
      # ------------------------------------------------------------
      mkdir -p "${dotRoot}"

      # ------------------------------------------------------------
      # APPLICATION SUPPORT: MIGRATE + SYMLINK
      # ------------------------------------------------------------
      mkdir -p "${dotAsDir}"

      if [ -L "${asPath}" ]; then
        rm -f "${asPath}"
      fi

      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        echo "Migrating Application Support → dotfiles"
        mv "${asPath}/"* "${dotAsDir}/" 2>/dev/null || true
        rmdir "${asPath}" 2>/dev/null || true
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotAsDir}" "${asPath}"

      # ------------------------------------------------------------
      # PREFERENCES PLIST A: com.publicspace.abfa.plist
      # ------------------------------------------------------------
      if [ -f "${prefPlistA}" ] && [ ! -L "${prefPlistA}" ] && [ ! -f "${dotPlistA}" ]; then
        echo "Moving plist → dotfiles: $(basename "${prefPlistA}")"
        mv "${prefPlistA}" "${dotPlistA}"
      fi

      [ -f "${dotPlistA}" ] || : > "${dotPlistA}"
      ln -sfn "${dotPlistA}" "${prefPlistA}"

      # ------------------------------------------------------------
      # PREFERENCES PLIST B: net.publicspace.abfa7.plist
      # ------------------------------------------------------------
      if [ -f "${prefPlistB}" ] && [ ! -L "${prefPlistB}" ] && [ ! -f "${dotPlistB}" ]; then
        echo "Moving plist → dotfiles: $(basename "${prefPlistB}")"
        mv "${prefPlistB}" "${dotPlistB}"
      fi

      [ -f "${dotPlistB}" ] || : > "${dotPlistB}"
      ln -sfn "${dotPlistB}" "${prefPlistB}"

      echo "Done: ${asName}"
    '';
}
