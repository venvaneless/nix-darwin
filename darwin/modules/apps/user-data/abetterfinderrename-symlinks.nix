# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/abetterfinderrename-symlinks.nix
#
# DARWIN: A BETTER FINDER RENAME USER-DATA
# ============================================================
# A Better Finder Rename is a bulk file renaming tool for macOS.
#
# Moves app state into ven-dots and symlinks it back:
#   - Application Support folder
#   - Preferences plist
#
# Source of truth:
#   /Users/ven/ven-dots/user-data/apps/a_better_finder_rename
# ============================================================

{ config, lib, ... }:

let
  # PATHS: ROOTS
  # ------------------------------------------------------------
  home    = config.home.homeDirectory;
  dotsApp = "/Users/ven/ven-dots/user-data/apps";

  # APP: IDENTIFIERS
  # ------------------------------------------------------------
  appFolder = "a_better_finder_rename";
  asName    = "A Better Finder Rename";

  # APP: RUNTIME PATHS
  # ------------------------------------------------------------
  asPath    = "${home}/Library/Application Support/${asName}";
  prefPlist = "${home}/Library/Preferences/com.publicspace.abfr.plist";

  # APP: DOTFILES PATHS
  # ------------------------------------------------------------
  dotRoot  = "${dotsApp}/${appFolder}";
  dotPlist = "${dotRoot}/com.publicspace.abfr.plist";

  # PLIST MODE
  # ------------------------------------------------------------
  # "single" = store plist directly in dotRoot
  # "multi"  = store plists under dotRoot/Preferences/
  plistMode = "single";
in
{
  home.activation.abfrUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing user-data: ${asName}"

      # DOTFILES: ENSURE ROOT EXISTS
      # ------------------------------------------------------------
      mkdir -p "${dotRoot}"

      # APPLICATION SUPPORT: MIGRATE + SYMLINK
      # ------------------------------------------------------------
      if [ -L "${asPath}" ]; then
        rm -f "${asPath}"
      fi

      if [ -d "${asPath}" ] && [ ! -L "${asPath}" ]; then
        echo "Migrating Application Support → dotfiles"
        mkdir -p "${dotRoot}"
        mv "${asPath}/"* "${dotRoot}/" 2>/dev/null || true
        rmdir "${asPath}" 2>/dev/null || true
      fi

      rm -rf "${asPath}" 2>/dev/null || true
      ln -sfn "${dotRoot}" "${asPath}"

      # PREFERENCES: MIGRATE + SYMLINK
      # ------------------------------------------------------------
      if [ "${plistMode}" = "multi" ]; then
        mkdir -p "${dotRoot}/Preferences"
        dotPlistPath="${dotRoot}/Preferences/$(basename "${prefPlist}")"
      else
        dotPlistPath="${dotPlist}"
      fi

      if [ -f "${prefPlist}" ] && [ ! -L "${prefPlist}" ] && [ ! -f "$dotPlistPath" ]; then
        echo "Moving plist → dotfiles"
        mv "${prefPlist}" "$dotPlistPath"
      fi

      if [ ! -f "$dotPlistPath" ]; then
        : > "$dotPlistPath"
      fi

      ln -sfn "$dotPlistPath" "${prefPlist}"

      echo "Done: ${asName}"
    '';
}
