# /Users/ven/.config/nix/nix-config/darwin/modules/apps/apps.nix
#
# ============================================================
# LOAD APPS
# 
# This file imports individual installers for apps
# and enables selected user-facing programs.
# ============================================================

{ ... }:

{
  imports = [
    ./abetterfinderattributes.nix
    ./abetterfinderrename.nix
    ./assetsnap.nix
    ./calibre.nix
    ./devdocs.nix
    ./devtoys.nix
    ./espanso.nix
    ./hammerspoon.nix
    ./helium-browser.nix
    ./iterm.nix
    ./jdownloader.nix
    ./keyboardSwitcher.nix
    ./kiwix.nix
    ./librewolf.nix
    ./obsidian.nix
    ./paste.nix
    ./pearcleaner.nix
    ./raycast.nix
    ./simplenote.nix
    ./thaw.nix
    ./vlc.nix
    ./vscode.nix
    ./vesktop.nix
    ./wezterm.nix
    ./zed.nix
    ./yate.nix
  ];
}
