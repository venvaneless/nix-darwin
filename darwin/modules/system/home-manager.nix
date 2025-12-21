# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/home-manager.nix
#
# DARWIN: HOME MANAGER (INTEGRATED)
# ================================================
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
# ================================================

{ pkgs, lib, inputs, ... }:

{
  # --- Main User ---
  home-manager = {
    useGlobalPkgs   = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.ven = {
      home.username      = "ven";
      home.homeDirectory = "/Users/ven";
      home.stateVersion  = "25.11+relink";
      
      # --- Astrovim config --- #
      home.packages = [
        pkgs.neovim
      ];
      
      programs.neovide = {
        enable = true;
      
        settings = {
          frame = "full";
          idle = true;
          maximized = true;
        };
      };
      
      # --- User modules ---
      imports = [
        ../terminal/zsh.nix
        ../apps/user-data/symlinking.nix
        ./hm-options.nix
        ./icloud-symlink.nix
      ];
    };
  };
}
