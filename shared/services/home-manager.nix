# /Users/ven/dotfiles/nix/shared/services/home-manager.nix
#
# HOME MANAGER SHARED SERVICE
# ============================================================
# Enables and configures Home Manager for the user "ven".
# Works under nix-darwin and as a standalone Home Manager flake output.
# ============================================================

{ pkgs, lib, home-manager, inputs, ... }:

{
  # --- Enable Home Manager module within nix-darwin (macOS) ---
  imports = [
    home-manager.darwinModules.home-manager
  ];

  # --- Make `home-manager` CLI available system-wide ---
  environment.systemPackages = [
    home-manager.packages.${pkgs.system}.default
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.ven = {
      home = {
        username      = "ven";
        homeDirectory = lib.mkForce "/Users/ven";
        stateVersion  = "25.11";
      };

      # User-level modules managed by Home Manager
      imports = [
        ../../darwin/modules/terminal/zsh.nix
        ../../darwin/modules/apps/user-data/symlinking.nix
      ];
    };
  };

  # --- System-level environment for Nix + Zsh ---
  environment.systemPath = [
    pkgs.nix
  ];
}
