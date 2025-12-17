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
  		./abetterfinderattributes.nix
    	./abetterfinderrename.nix
    	./appcleaner.nix
      ./espanso.nix
      ./iterm.nix
      ./masscode.nix
      ./obsidian.nix
      ./paste.nix
      ./raycast.nix
      ./vlc.nix
      ./wezterm.nix
      ./zed.nix
      ./yate.nix
  ];
}
