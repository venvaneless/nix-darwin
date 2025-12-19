# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/iterm.nix

# ITERM2: INSTALL APP
# ============================================================
# Installs the iTerm2 Terminal for macOS to a chosen folder
# through homebrew
# ============================================================

# nix-darwin system module: installs iTerm2.app system-wide.

{ ... }:

let
  appName   = "Hammerspoon.app";
  caskName  = "hammerspoon";
  targetDir = "/Applications/System";
in
{
  homebrew.casks = [
    { name = caskName; args = { appdir = targetDir; }; }
  ];

  system.activationScripts.ensureItermAppDir.text = ''
    mkdir -p "${targetDir}"
  '';
}
