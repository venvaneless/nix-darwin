# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/appcleaner.nix
#
# APPCLEANER: INSTALL APP
# ============================================================
# Installs AppCleaner for macOS via Homebrew cask and places it
# into a custom Applications directory.
# ============================================================

{ ... }:

let
  # APP METADATA
  # ------------------------------------------------------------
  appName   = "AppCleaner.app";
  caskName  = "appcleaner";
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
  system.activationScripts.ensureAppCleanerAppDir.text = ''
    mkdir -p "${targetDir}"
  '';
}
