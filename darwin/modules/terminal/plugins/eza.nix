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
 	# Install and enable eza and integrate it with fish shell
    enable = true;
    enableFishIntegration = true;

    # Enable icons
    icons = "always";

    # Enable colors
    colors = "always";

    # Enable git
    git = true;
  };

  # Keep existing user-owned theme and supporting files in place
  home.sessionVariables.EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
}
