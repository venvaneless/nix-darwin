# /Users/ven/.config/nix/nix-config/darwin/modules/apps/apps.nix
#
# =====================================================================
# LOAD APPS
# 
# This file imports individual installers for apps
# and enables selected user-facing programs
# =====================================================================

{ ... }:

{
  imports = [
    ./abetterfinderattributes.nix
    ./abetterfinderrename.nix
    ./devdocs.nix
    ./devtoys.nix
    ./espanso.nix
    # ./hammerspoon.nix
    ./helium-browser.nix
    # ./iterm.nix
    ./jdownloader.nix
    ./keyboardSwitcher.nix
    ./obsidian.nix
    ./paste.nix
    ./pearcleaner.nix
    ./raycast.nix
    ./simplenote.nix
    ./vscode.nix
    ./wezterm.nix
    ./zed.nix
    ./yate.nix
  ];
}
