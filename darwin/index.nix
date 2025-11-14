# /Users/ven/dotfiles/nix/darwin/index.nix

{ config, pkgs, lib, inputs, ... }:

{
  # ----- Primary user -----
  system.primaryUser = "ven";
  system.stateVersion = lib.mkForce 6;

  # ===== DEBUG ACTIVATION TEST =====
  # This runs as part of the main activation script via extraActivation.
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> VEN: extraActivation hook at $(date)" > /tmp/ven-activation-proof
  '';

  imports = [
    # --- system modules ---
    ./modules/system/base.nix
    ./modules/system/homebrew.nix
    ./modules/terminal/shell.nix
    ./modules/services/nix-homebrew.nix
    ./modules/services/script-services.nix
    ./modules/apps/apps.nix

    # --- home-manager last ---
    ../shared/services/home-manager.nix
  ];
}
