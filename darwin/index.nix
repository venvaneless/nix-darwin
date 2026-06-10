# /Users/ven/.config/nix/nix-darwin/darwin/index.nix
#
# DARWIN: MAIN SYSTEM MODULE
# ================================================
# This file glues together:
#   - nix-darwin system configuration
#   - integrated Home Manager configuration
#   - all system-level modules (brew, nginx, scripts, docker, etc.)
#
# Notes:
#   - Home Manager is enabled ONLY through nix-darwin
#   - No standalone HM mode is used
#   - User-level modules live under darwin/modules/system/home-manager.nix
# ================================================

{ lib, home-manager, pkgs, ... }:

{
  # ------------------------------------------------------------
  # Primary user
  # ------------------------------------------------------------
  # Main macOS user managed by nix-darwin.
  # Fish is set as the default login shell.
  # ------------------------------------------------------------

  system = {
    primaryUser = "ven";
    stateVersion = lib.mkForce 6;
  };

  users = {
    knownUsers = [ "ven" ];

    users.ven = {
    	uid = 502;
      home = "/Users/ven";
      shell = pkgs.fish;
    };
  };

  # ------------------------------------------------------------
  # Home Manager
  # ------------------------------------------------------------
  # Home Manager runs fully through nix-darwin.
  # Backup files use the .bak extension.
  # ------------------------------------------------------------

  home-manager = {
    backupFileExtension = "bak";
  };

  # ------------------------------------------------------------
  # Fish shell
  # ------------------------------------------------------------
  programs.fish.enable = true;

  environment.shells = [
    pkgs.fish
  ];

  # ------------------------------------------------------------
  # Module imports
  # 
  # Loads all nix-darwin modules:
  # ------------------------------------------------------------

  imports = [

    # Home Manager
    home-manager.darwinModules.home-manager
    ./da/home/home-manager.nix

    # System
    ./modules/system/base.nix
    ./modules/system/homebrew.nix

    # Services
    ./modules/services/services.nix
    ./modules/services/pdf-tools.nix

    # Apps
    ./modules/apps/apps.nix
  ];
}