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
    ./calibre.nix
    # ./astrovim.nix
    ./espanso.nix
    ./hammerspoon.nix
    ./helium-browser.nix
    ./iterm.nix
    ./jdownloader.nix
    ./kiwix.nix
    ./obsidian.nix
    ./paste.nix
    ./pearcleaner.nix
    ./proton-mail-bridge.nix
    ./raycast.nix
    ./simplenote.nix
    ./thaw.nix
    ./vlc.nix
    ./vesktop.nix
    ./wezterm.nix
    ./zed.nix
    ./yate.nix
  ];
}
