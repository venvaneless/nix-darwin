# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/eza.nix
# 
# =====================================================================
# EZA
# 
# Modern, maintained replacement for ls
# =====================================================================

{ ... }:

{
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    icons = "always";
    colors = "always";
    git = true;
  };

  xdg.configFile."eza/theme.yml".source =
    /Users/ven/.config/eza/theme.yml;
}