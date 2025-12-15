# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/a-better-finder-attributes.nix
#
# A BETTER FINDER ATTRIBUTES: INSTALL APP
# ============================================================
# Installs "A Better Finder Attributes" for macOS via Homebrew
# cask and places it into a custom Applications directory.
# ============================================================

{ ... }:

let
  # APP METADATA
  # ------------------------------------------------------------
  appName   = "A Better Finder Attributes.app";
  caskName  = "a-better-finder-attributes";
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
  system.activationScripts.ensureABFAttributesAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
