# DARWIN: CHROMIUM PROFILE + PLIST MIGRATION (ONE-TIME MOVE + SYMLINK)
# ====================================================================
# Moves the Chromium profile directory and plist into ven-dots and
# symlinks them back.
#
# Profile dir:
#   AS = ~/Library/Application Support/Chromium
#   VD = /Users/ven/ven-dots/apps/chromium
#
# Plist:
#   Preferences plist:
#     ~/Library/Preferences/org.chromium.Chromium.plist
#   ven-dots plist:
#     /Users/ven/ven-dots/apps/chromium/org.chromium.Chromium.plist
#
# Behavior:
#   Directory:
#     - If AS is a symlink to VD:
#         -> Do nothing.
#     - If AS is a real dir and VD does not exist:
#         -> Move AS -> VD, then create symlink AS -> VD.
#     - If AS does not exist and VD exists:
#         -> Create symlink AS -> VD.
#     - If neither AS nor VD exists:
#         -> Create VD, then symlink AS -> VD.
#     - If both AS and VD exist as real dirs (no symlink):
#         -> Print warning and do nothing (manual fix needed).
#
#   Plist:
#     - If Preferences plist is a symlink to VD plist:
#         -> Do nothing.
#     - If Preferences plist is a real file and VD plist does not exist:
#         -> Move plist -> VD, symlink Preferences -> VD plist.
#     - If Preferences plist does not exist and VD plist exists:
#         -> Symlink Preferences -> VD plist.
#     - If both exist as real files:
#         -> Print warning and do nothing (manual fix needed).
#     - If neither exists:
#         -> Do nothing; Chromium will create a plist later.
#
# After successful migration and verification, you can remove this module
# from imports so it never runs again.
# ====================================================================

{ config, lib, pkgs, ... }:

let
  home       = config.home.homeDirectory;
  appsRoot   = "/Users/ven/ven-dots/apps";
  vd         = "${appsRoot}/chromium";  # ven-dots profile dir

  asChromium = "${home}/Library/Application Support/Chromium";

  prefPlist  = "${home}/Library/Preferences/org.chromium.Chromium.plist";
  vdPlist    = "${vd}/org.chromium.Chromium.plist";
in
{
  home.activation.chromiumMigrate =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu

      echo "=== Chromium profile migration ==="
      echo "  Application Support: ${asChromium}"
      echo "  ven-dots profile   : ${vd}"

      # Ensure ven-dots/apps root exists
      if [ ! -d "${appsRoot}" ]; then
        echo "  - Creating apps root: ${appsRoot}"
        mkdir -p "${appsRoot}"
      fi

      # ----------------------------------------------------------------
      # PROFILE DIRECTORY MIGRATION
      # ----------------------------------------------------------------

      # Case 0: AS is already a symlink
      if [ -L "${asChromium}" ]; then
        target="$(readlink "${asChromium}" || true)"
        if [ "${target}" = "${vd}" ]; then
          echo "  - Chromium Application Support already symlinked to ven-dots."
        else
          echo "  ! WARNING: ${asChromium} is a symlink to ${target}, not ${vd}."
          echo "    Not modifying it. Please fix manually if this is unexpected."
        fi
      else
        # At this point, AS is either a real dir, a file, or does not exist.

        if [ -d "${asChromium}" ] && [ ! -e "${vd}" ]; then
          # Case A: Existing profile in AS, ven-dots missing -> move it.
          echo "  - Migrating existing Chromium profile into ven-dots..."
          mkdir -p "$(dirname "${vd}")"
          mv "${asChromium}" "${vd}"
        elif [ ! -e "${asChromium}" ] && [ -d "${vd}" ]; then
          # Case B: No AS dir, but ven-dots profile exists -> just link.
          echo "  - No Application Support profile; using existing ven-dots profile."
        elif [ ! -e "${asChromium}" ] && [ ! -e "${vd}" ]; then
          # Case C: Completely fresh setup -> create empty profile dir in ven-dots.
          echo "  - No existing profile found. Creating empty ven-dots profile directory."
          mkdir -p "${vd}"
        elif [ -d "${asChromium}" ] && [ -d "${vd}" ]; then
          # Case D: Both exist as real directories -> ambiguous, do nothing.
          echo "  ! WARNING: Both ${asChromium} and ${vd} exist as real directories."
          echo "    Not modifying either. Please reconcile manually."
        else
          # Catch-all for unexpected file types (e.g. regular file at AS)
          echo "  ! WARNING: Unexpected filesystem state for Chromium profile."
          echo "    ${asChromium} or ${vd} is not a directory/symlink as expected."
          echo "    Not modifying the profile directory."
        fi

        # Ensure AS is a symlink pointing to VD if AS does not exist now
        if [ ! -e "${asChromium}" ] && [ -d "${vd}" ]; then
          echo "  - Creating symlink: ${asChromium} -> ${vd}"
          ln -s "${vd}" "${asChromium}"
        fi
      fi

      # ----------------------------------------------------------------
      # PLIST MIGRATION
      # ----------------------------------------------------------------

      echo "=== Chromium plist migration ==="
      echo "  Preferences plist: ${prefPlist}"
      echo "  ven-dots plist   : ${vdPlist}"

      if [ -L "${prefPlist}" ]; then
        plistTarget="$(readlink "${prefPlist}" || true)"
        if [ "${plistTarget}" = "${vdPlist}" ]; then
          echo "  - Plist already symlinked to ven-dots. Nothing to do."
        else
          echo "  ! WARNING: Plist symlink points to ${plistTarget}, not ${vdPlist}."
          echo "    Not modifying it. Please fix manually if this is unexpected."
        fi
      elif [ -f "${prefPlist}" ] && [ ! -e "${vdPlist}" ]; then
        echo "  - Moving existing plist into ven-dots and symlinking..."
        mkdir -p "$(dirname "${vdPlist}")"
        mv "${prefPlist}" "${vdPlist}"
        ln -s "${vdPlist}" "${prefPlist}"
      elif [ ! -e "${prefPlist}" ] && [ -f "${vdPlist}" ]; then
        echo "  - Preferences plist missing; linking from ven-dots."
        ln -s "${vdPlist}" "${prefPlist}"
      elif [ -f "${prefPlist}" ] && [ -f "${vdPlist}" ]; then
        echo "  ! WARNING: Both Preferences plist and ven-dots plist exist as real files."
        echo "    Not modifying either. Please reconcile manually."
      else
        echo "  - No plist migration needed at this time."
      fi

      echo "=== Chromium migration complete ==="
    '';
}
