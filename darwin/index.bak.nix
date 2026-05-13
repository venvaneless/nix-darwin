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

# ------------------------------------------------------------
# --- SYSTEM --- 
# ------------------------------------------------------------

{	

  # ----- Primary user -----
  system.primaryUser  = "ven";
  system.stateVersion = lib.mkForce 6;
  
  users.users.ven.home = "/Users/ven";
  home-manager.backupFileExtension = "bak";

  # Enable Fish at the nix-darwin system level
  programs.fish.enable = true;

  # Set Fish as Ven's login shell.
  users.users.ven.shell = pkgs.fish;

  # Register Fish as a valid login shell.
  environment.shells = [
    pkgs.fish
  ];


  # ------------------------------------------------------------
  # 
  # --- MODULE IMPORTS ---
  # ------------------------------------------------------------
  imports = [

    # --- HOME MANAGER INTEGRATION ---
    # ------------------------------------------------------------
    # Enables Home Manager as part of nix-darwin.
    home-manager.darwinModules.home-manager

    # User configuration for Home-Manager
    ./modules/home/home-manager.nix

    # --- SYSTEM MODULES ---
    ./modules/system/base.nix
    ./modules/system/homebrew.nix

    # --- Services & Tools ---
    ./modules/services/services.nix
    ./modules/services/pdf-tools.nix

    # --- Apps ---
    ./modules/apps/apps.nix
  ];
}
