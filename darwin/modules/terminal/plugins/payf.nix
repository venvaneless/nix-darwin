{ config, pkgs, ... }:

{
  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;

    # Set alias => this replaces default
    options = [
      "--alias"
      "m"
    ];
  };
}
