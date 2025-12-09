# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/iterm.nix

# ITERM2: INSTALL APP
# ============================================================
# Installs the iTerm2 Terminal for macOS to a chosen folder
# through homebrew
# ============================================================

# nix-darwin system module: installs iTerm2.app system-wide.

{ ... }:

let
  appName   = "Obsidian.app";
  caskName  = "obsidian";
  targetDir = "/Applications/Productivity";
in
{
  homebrew.casks = [
    { name = caskName; args = { appdir = targetDir; }; }
  ];

  system.activationScripts.ensureItermAppDir.text = ''
    mkdir -p "${targetDir}"
  '';
}
