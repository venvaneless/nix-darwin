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

{ lib, home-manager, ... }:

# ------------------------------------------------------------
# --- SYSTEM --- 
# ------------------------------------------------------------

{	

  # ----- Primary user -----
  system.primaryUser  = "ven";
  system.stateVersion = lib.mkForce 6;
    
  users.users.ven = {
    home = "/Users/ven";
    # Add groups here:
    extraGroups = [ "containers" ];
  };



  
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
    ./modules/system/home-manager.nix
    ./modules/system/user-groups.nix
    
    # --- SYSTEM MODULES ---
    ./modules/system/base.nix
    ./modules/system/homebrew.nix

    # --- Services & Tools ---
    ./modules/services/services.nix
    ./modules/services/pdf-tools.nix

    # --- Apps ---
    ./modules/apps/apps.nix

    # --- Docker ---
    # ------------------------------------------------------------
    # ./modules/services/docker/docker-all.nix
  ];
}
