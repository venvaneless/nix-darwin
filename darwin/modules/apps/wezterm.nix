# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/wezterm.nix

# ITERM2: INSTALL APP
# ============================================================
# Installs the Wezterm Terminal for macOS to a chosen folder
# through homebrew
# ============================================================

# nix-darwin system module: installs iTerm2.app system-wide.

{ ... }:

let
  appName   = "Wezterm.app";
  caskName  = "wezterm";
  targetDir = "/Applications/Programming";
in
{
  homebrew.casks = [
    { name = caskName; args = { appdir = targetDir; }; }
  ];

  system.activationScripts.ensureItermAppDir.text = ''
    mkdir -p "${targetDir}"
  '';
}
