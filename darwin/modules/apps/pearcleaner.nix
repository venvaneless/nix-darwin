# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/paste.nix
#
# PASTE: INSTALL APP
# ============================================================
# Installs "Paste" for macOS via Homebrew cask and places it
# into a custom Applications directory.
# ============================================================

{ ... }:

let
  # APP METADATA
  # ------------------------------------------------------------
  appName   = "Pearcleaner.app";
  caskName  = "pearcleaner";
  targetDir = "/Applications/System";
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
  system.activationScripts.ensurePearcleanerAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
