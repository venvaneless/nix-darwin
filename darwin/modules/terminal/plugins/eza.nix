# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/eza.nix
# 
# =====================================================================
# EZA
# 
# Modern, maintained replacement for ls
# =====================================================================

{ config, ... }:

{
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    icons = "always";
    colors = "always";
    git = true;
  };

  # Keeps the existing user-owned theme and supporting files in place.
  home.sessionVariables.EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
}
