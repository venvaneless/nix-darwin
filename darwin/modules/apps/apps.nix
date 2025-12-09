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
   	./iterm.nix
    ./obsidian.nix
    ./wezterm.nix
    ./zed.nix
  ];
}
