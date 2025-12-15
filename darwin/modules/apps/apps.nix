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
    ./appcleaner.nix
  	./espanso.nix
   	./iterm.nix
    ./mas.nix
    ./obsidian.nix
    ./paste.nix
    ./raycast.nix
    ./vlc.nix
    ./wezterm.nix
    ./zed.nix
    ./yate.nix
  ];
}
