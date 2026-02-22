# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/apps.nix
#
# LOAD APPS
# ============================================================
# This file only imports individual installers for apps
# and enables selected user-facing programs.
# ============================================================

{ ... }:

{
  imports = [
    ./abetterfinderattributes.nix
    ./abetterfinderrename.nix
    ./appcleaner.nix
    # ./astrovim.nix
    ./espanso.nix
    ./hammerspoon.nix
    ./iterm.nix
    ./obsidian.nix
    ./paste.nix
    ./pearcleaner.nix
    ./raycast.nix
    ./vlc.nix
    ./wezterm.nix
    ./zed.nix
    ./yate.nix
  ];
}
