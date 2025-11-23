# /Users/ven/dotfiles/nix/shared/services/home-manager.nix
#
# HOME MANAGER SHARED SERVICE
# ============================================================
# Enables and configures Home Manager for the user "ven".öä.eqw# Works under both nix-darwin and Linux (NixOS / standalone).
# ============================================================

{ pkgs, lib, home-manager, inputs, ... }:

{
  # --- Enable Home Manager module within nix-darwin (macOS) ---
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
        homeDirectory = lib.mkForce "/Users/ven"; # or "/home/ven" on Linux
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

  # --- System-level environment for Nix + Zsh (add this block)
  environment.systemPath = [
    pkgs.nix
  ];
}
