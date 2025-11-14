# /Users/ven/dotfiles/nix/shared/services/home-manager.nix
#
# HOME MANAGER SHARED SERVICE
# ============================================================
# Enables and configures Home Manager for the user "ven".
# Works under both nix-darwin and Linux (NixOS / standalone).
# ============================================================

{ pkgs, lib, home-manager, inputs, ... }:

{
  # --- Enable Home Manager module within nix-darwin ---
  imports = [
    home-manager.darwinModules.home-manager
  ];

  environment.systemPackages = [
    home-manager.packages.${pkgs.system}.default
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.ven = {
      home = {
        username = "ven";
        homeDirectory = lib.mkForce "/Users/ven";
        stateVersion = "25.11";
      };

      # Moved from index.nix — user-level modules
      imports = [
        ../../shared/home/index.nix
        ../../darwin/modules/terminal/zsh.nix
        ../../darwin/modules/apps/user-data/symlinking.nix
      ];
    };
  };
}
