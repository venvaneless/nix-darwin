# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/bottom.nix
# 
# =============================================================
# BOTTOM
# 
# Cross-platform graphical process/system monitor
# ============================================================

{ pkgs, ... }:

{
  home.packages = [ pkgs.bottom ];

  xdg.configFile."bottom".source =
    /Users/ven/.config/bottom;
}