# /Users/ven/dotfiles/nix/shared/services/home-manager.nix
#
# HOME MANAGER SHARED SERVICE
# ============================================================
# Home Manager user configuration for "ven".
# This file MUST NOT import `home-manager.darwinModules.home-manager`.
# That module belongs only in `darwin/index.nix`.
# ============================================================

{ pkgs, lib, ... }:

{
  # --- Home Manager (user session configuration only) ---
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

  # --- Expose HM CLI ---
  environment.systemPackages = [
    pkgs.home-manager
  ];

  # --- System-level environment for Nix ---
  environment.systemPath = [
    pkgs.nix
  ];
}
