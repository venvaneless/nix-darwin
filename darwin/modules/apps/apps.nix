# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/apps.nix
# 
# LOAD APPS
# ============================================================
# # This file only imports individual installers for
# apps.
# ============================================================

{ ... }:
{
  imports = [
  	./espanso.nix
   	./iterm.nix
    ./obsidian.nix
    ./raycast.nix
    ./wezterm.nix
    ./zed.nix
  ];
}
