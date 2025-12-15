# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/a-better-finder-rename.nix
#
# A BETTER FINDER RENAME: INSTALL APP
# ============================================================
# Installs "A Better Finder Rename" for macOS via Homebrew cask
# and places it into a custom Applications directory.
# ============================================================

{ ... }:

let
  # APP METADATA
  # ------------------------------------------------------------
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
  system.activationScripts.ensureABFRAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
