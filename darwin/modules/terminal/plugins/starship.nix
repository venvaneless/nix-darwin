# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/starship.nix
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
    # ---------- Starship paths ---------- #
    set -gx STARSHIP_CONFIG "${config.home.homeDirectory}/.config/starship.toml"
    set -gx STARSHIP_CACHE "${config.home.homeDirectory}/.config/.cache/"
  '';
}