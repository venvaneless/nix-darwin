# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/eza.nix
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

  programs.fish.shellInit = ''
    # ---------- Eza config ---------- #
    set -gx EZA_CONFIG_DIR "$HOME/.config/eza"
  '';
}