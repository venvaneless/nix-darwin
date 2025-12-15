# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/a-better-finder-rename.nix

# A BETTER FINDER RENAME: INSTALL APP
# ============================================================
# Installs "A Better Finder Rename" for macOS via Homebrew cask
# and ensures the target Applications directory exists.
# ============================================================
#
# nix-darwin system module: installs the app system-wide.

{ pkgs, ... }:

let
  appName   = "A Better Finder Rename.app";
  caskName  = "a-better-finder-rename";
  targetDir = "/Applications/Tools";
in
{
  # HOMEBREW CASK INSTALL
  # ------------------------------------------------------------
  homebrew.casks = [
    {
      name = caskName;
      args = { appdir = targetDir; };
    }
  ];

  # DARWIN: ENSURE APPLICATION DIRECTORY EXISTS
  # ------------------------------------------------------------
  system.activationScripts.ensureABFRAppDir =
    pkgs.writeShellScriptBin "ensure-abfr-app-dir" ''
      #!/bin/bash
      set -euo pipefail

      if [ ! -d "${targetDir}" ]; then
        echo "[ABFR] Creating application directory: ${targetDir}"
        mkdir -p "${targetDir}"
      else
        echo "[ABFR] Application directory already exists: ${targetDir}"
      fi
    '';
}
