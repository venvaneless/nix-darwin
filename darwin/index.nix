# /Users/ven/dotfiles/nix/darwin/index.nix

{ config, pkgs, lib, inputs, ... }:

{
  # ----- Primary user -----
  system.primaryUser = "ven";
  system.stateVersion = lib.mkForce 6;

  # ----- Debug test -----
  system.activationScripts.testScript.text = ''
    echo "Activation test executed at $(date)" > /tmp/ven-activation-proof
  '';

  # === PROOF FILE: this is the undeniable part ===
     environment.etc."ven-flake-proof".text = ''
       FLAKE IS ALIVE
       COMMIT = ${config.system.nixpkgs.release or "unknown"}
     '';

  imports = [
    # --- system first ---
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
