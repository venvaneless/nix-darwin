{ config, pkgs, lib, home-manager, ... }:

{
  config = {
    # ----- Primary user -----
    system.primaryUser = "ven";

    # ----- Debug test -----
    system.activationScripts.testScript.text = ''
      echo "Activation test executed at $(date)" > /tmp/ven-activation-proof
    '';
  };

  imports = [
    ./modules/system/base.nix
    ./modules/system/homebrew.nix
    ./modules/terminal/shell.nix
    ./modules/services/nix-homebrew.nix
    ./modules/services/script-services.nix
    ./modules/apps/apps.nix
  ];
}
