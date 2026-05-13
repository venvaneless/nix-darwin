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
  # Enables Fish system-wide and registers it
  # as a valid login shell on macOS.
  # ------------------------------------------------------------

  programs.fish.enable = true;

  environment.shells = [
    pkgs.fish
  ];

  # ------------------------------------------------------------
  # Module imports
  # ------------------------------------------------------------
  # Loads all nix-darwin modules:
  #   - Home Manager
  #   - system config
  #   - services
  #   - apps
  # ------------------------------------------------------------

  imports = [

    # Home Manager
    # User-level Home Manager configuration
    home-manager.darwinModules.home-manager
    ./modules/home/home-manager.nix

    # System
    # Core nix-darwin system configuration
    ./modules/system/base.nix
    ./modules/system/homebrew.nix

    # Services
    # System services and PDF tools
    ./modules/services/services.nix
    ./modules/services/pdf-tools.nix

    # Apps
    # GUI applications and app bundles
    ./modules/apps/apps.nix
  ];
}