# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/apps.nix
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
    # ./astrovim.nix
    ./espanso.nix
    ./hammerspoon.nix
    ./helium-browser.nix
    ./iterm.nix
    ./kiwix.nix
    ./obsidian.nix
    ./paste.nix
    ./pearcleaner.nix
    ./proton-mail-bridge.nix
    ./raycast.nix
    ./simplenote.nix
    ./vlc.nix
    ./wezterm.nix
    ./zed.nix
    ./yate.nix
  ];
}
