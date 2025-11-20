# /Users/ven/dotfiles/nix/darwin/index.nix

{ lib, ... }:

{
  # ----- Primary user -----
  system.primaryUser = "ven";
  system.stateVersion = lib.mkForce 6;

  # ===== DEBUG ACTIVATION TEST =====
  # This runs as part of the main activation script via extraActivation.

  imports = [


    # --- system modules ---
    ./modules/system/base.nix
    ./modules/system/homebrew.nix
    ./modules/terminal/shell.nix
    ./modules/services/nix-homebrew.nix
    ./modules/services/script-services.nix
    ./modules/services/pdf-tools.nix
    ./modules/apps/apps.nix

    # --- docker ---
    ./modules/services/docker.nix
    ./modules/services/vaultwarden.nix
    # ./modules/services/vaultwarden-nginx.nix
    ./modules/services/vaultwarden-nginx-test.nix

   	# --- home-manager last ---
    ../shared/services/home-manager.nix
  ];
}
