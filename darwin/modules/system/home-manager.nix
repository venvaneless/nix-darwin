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
  home-manager = {
    useGlobalPkgs   = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.ven = {
      home.username      = "ven";
      home.homeDirectory = "/Users/ven";
      home.stateVersion  = "25.11";
      home.file."hm-proof.txt".text = "HM was here";

      # --- Reserved for future user packages ---
      home.packages = [
      ];

      # --- User modules ---
      imports = [
        ../terminal/zsh.nix
        ../terminal/nvim.nix
        ../apps/user-data/symlinking.nix
        ./hm-options.nix
        ./icloud-symlink.nix
      ];
    };
  };
}
