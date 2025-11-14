# /Users/ven/dotfiles/nix/darwin/index.nix
# VEN_DEBUG_MARKER_FINAL

{ config, pkgs, lib, ... }:

{
  config = {
    system.primaryUser = "ven";

    # === Debug flare test ===
    system.activationScripts.venDebug.text = ''
      echo ">>> VEN: The flake is ALIVE at $(date)"
    '';
  };

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
