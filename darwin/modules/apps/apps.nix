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
  	./a-better-finder-attributes.nix
   	./a-better-finder-rename.nix
  	./espanso.nix
   	./iterm.nix
    ./obsidian.nix
    ./raycast.nix
    ./wezterm.nix
    ./zed.nix
  ];
}
