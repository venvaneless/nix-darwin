# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/appcleaner.nix
#
# APPCLEANER: INSTALL APP
# ============================================================
# Installs AppCleaner for macOS via Homebrew cask and places it
# into a custom Applications directory.
# ============================================================

# nix-darwin system module: installs iTerm2.app system-wide.

{ ... }:

let
	# APP METADATA
  # ------------------------------------------------------------
  appName   = "AppCleaner.app";
  caskName  = "appcleaner";
  targetDir = "/Applications/System";
in
{
	# Homebrew cask install
  # ------------------------------------------------------------
  homebrew.casks = [
    { name = caskName; args = { appdir = targetDir; }; }
  ];

  # Ensure application directory exists
  # ------------------------------------------------------------
  system.activationScripts.ensureAppCleanerAppDir.text = ''
    mkdir -p "${targetDir}"
  '';
}
