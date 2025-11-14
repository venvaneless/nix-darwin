# /Users/ven/dotfiles/nix/darwin/index.nix
# VEN_DEBUG_MARKER_FINAL

{ config, pkgs, lib, inputs, ... }:

{
  # ----- Primary user -----
  system.primaryUser = "ven";
  system.stateVersion = lib.mkForce 6;

  # ===== DEBUG ACTIVATION TEST =====
  system.activationScripts.venDebug.text = ''
    echo ">>> VEN: The flake is ALIVE at $(date)" > /tmp/ven-activation-proof
  '';

  # ===== SYSTEM ETC PROOF FILE =====
  environment.etc."ven-flake-proof".text = ''
    FLAKE IS ALIVE
    COMMIT = ${config.system.nixpkgs.release or "unknown"}
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
