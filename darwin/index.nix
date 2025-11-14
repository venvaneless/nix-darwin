# /Users/ven/dotfiles/nix/darwin/index.nix
# VEN_DEBUG_MARKER_FINAL

{ config, pkgs, lib, ... }:

{
  config = {
    system.stateVersion = lib.mkForce 6;
    system.primaryUser = "ven";

    # === Debug flare test ===
    system.activationScripts.testScript.text = ''
      echo "Activation test executed at $(date)" > /tmp/ven-activation-proof
    '';

    # === Proof file ===
    environment.etc."ven-flake-proof".text = ''
      FLAKE IS ALIVE
      COMMIT = ${config.system.nixpkgs.release or "unknown"}
    '';
  };

  imports = [

    ./modules/system/base.nix
    ./modules/system/homebrew.nix
    ./modules/terminal/shell.nix
    ./modules/services/nix-homebrew.nix
    ./modules/services/script-services.nix

    ../shared/services/home-manager.nix

    ./modules/apps/apps.nix
  ];
}
