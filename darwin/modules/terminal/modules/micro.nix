# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/micro.nix
# 
# =====================================================================
# MICRO
# 
# Modern and intuitive terminal-based text editor
# =====================================================================

{ pkgs, ... }:

{
  home.packages = [ pkgs.micro ];

  xdg.configFile."micro".source =
    /Users/ven/.config/micro;
}