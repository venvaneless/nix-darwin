# /Users/ven/iCloudDocs/dotfiles/nix/darwin/modules/apps/zed.nix

# ZED: INSTALL APP
# ============================================================
# Installs the Zed editor app to a chosen folder
# through homebrew
# ============================================================

# nix-darwin system module: installs Zed.app system-wide.

{ ... }:

let
  appName   = "Zed.app";
  caskName  = "zed";
  targetDir = "/Applications/Productivity";
in
{
  homebrew.casks = [
    { name = caskName; args = { appdir = targetDir; }; }
  ];

  system.activationScripts.ensureZedAppDir.text = ''
    mkdir -p "${targetDir}"
  '';
}
