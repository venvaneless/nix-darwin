# /Users/ven/dotfiles/nix/darwin/index.nix
# VEN_DEBUG_MARKER_FINAL

{ config, pkgs, lib, ... }:

{
  # === Top-level Darwin options: NO "config = { ... }" wrapper ===
  system.stateVersion = lib.mkForce 6;
  system.primaryUser = "ven";

  # === Debug activation script ===
  system.activationScripts.testScript.text = ''
    echo "Activation test executed at $(date)" > /tmp/ven-activation-proof
  '';

  # === Proof file still works (valid Darwin option) ===
  environment.etc."ven-flake-proof".text = ''
    FLAKE IS ALIVE
    COMMIT = ${config.system.nixpkgs.release or "unknown"}
  '';

  # === Module imports at top-level (correct Darwin syntax) ===
  imports = [
    ../shared/services/home-manager.nix

    ./modules/system/base.nix
    ./modules/system/homebrew.nix
    ./modules/terminal/shell.nix
    ./modules/services/nix-homebrew.nix
    ./modules/services/script-services.nix

    ./modules/apps/apps.nix
  ];
}
