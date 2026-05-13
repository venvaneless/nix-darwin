# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/plugins/starship.nix
#
# =====================================================================
# STARSHIP
# 
# Cross-shell prompt for astronauts
# =====================================================================

{ config, ... }:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish.shellInit = ''
    set -gx STARSHIP_CONFIG "${config.home.homeDirectory}/.config/starship.toml"
    set -gx STARSHIP_CACHE "${config.home.homeDirectory}/.config/.cache/"
  '';
}