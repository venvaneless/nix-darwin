# /Users/ven/dotfiles/nix/darwin/index.nix

{ lib, home-manager, ... }:

{
  # ----- Primary user -----
  system.primaryUser = "ven";
  system.stateVersion = lib.mkForce 6;
  
  nix.enable = false;

  # ===== DEBUG ACTIVATION TEST =====

  imports = [
    # --- REQUIRED: Enable Home Manager inside nix-darwin ---
    home-manager.darwinModules.home-manager

    # --- User + HM config ---
    ../shared/services/home-manager.nix

    # --- system modules ---
    ./modules/system/base.nix
    ./modules/system/homebrew.nix	
    ./modules/services/script-services.nix
    ./modules/services/pdf-tools.nix
    ./modules/apps/apps.nix

    # --- docker ---
    ./modules/services/docker/docker-all.nix
  ];
}
