# /Users/ven/.config/nix/nix-config/darwin/modules/home/home-manager.nix
#
# =====================================================================
# DARWIN: HOME MANAGER (INTEGRATED)
# 
# This module enables Home Manager as part of nix-darwin.
# It applies your user config whenever you run:
#   drs / drb / drn  → darwin-rebuild
#
# Contains:
#   - user settings for "ven"
#   - imports of user-level modules (Zsh, symlinks, etc.)
#
# Does NOT contain:
#   - systemPath (belongs to nix-darwin system-level)
#   - systemPackages (belongs to system-level)
# =====================================================================

{ inputs, pkgs, ... }:

{
  home-manager = {
    useGlobalPkgs   = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.ven = {
      home.username      = "ven";
      home.homeDirectory = "/Users/ven";
      home.stateVersion  = "25.11";

      # --- Reserved for future user packages ---
      home.packages = [
        pkgs.bat
        pkgs.bottom
        pkgs.micro
      ];

      # --- User modules ---
      imports = [
      	../terminal/fish.nix
        ../terminal/nvim.nix
        ./hm-options.nix
      ];
    };
  };
}
