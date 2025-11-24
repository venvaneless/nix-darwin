# /Users/ven/dotfiles/nix/darwin/index.nix

{ lib, home-manager, ... }:

{
  system.primaryUser  = "ven";
  system.stateVersion = lib.mkForce 6;

  nix.enable = false;

  imports = [
    # -- Enables Home Manager system integration ---
    home-manager.darwinModules.home-manager

    # -- Enables Home Manager user integration ---
    ./modules/system/home-manager.nix

    # ------------------------------------------------------------
    # 
    # --- Modules
    # ------------------------------------------------------------
    ./modules/system/base.nix
    ./modules/services/pdf-tools.nix
    # Services and system tools
    ./modules/system/homebrew.nix
    # Homebrew
    ./modules/apps/apps.nix
    # Apps
    
    
    ./modules/services/script-services.nix
    # Scripts
    
    # -- Docker --
    ./modules/services/docker/docker-all.nix
  ];
}
