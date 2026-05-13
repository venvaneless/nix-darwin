# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/payf.nix
# 
# =====================================================================
# PAY-RESPECTS
# 
# thefuck replacement
# =====================================================================

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
