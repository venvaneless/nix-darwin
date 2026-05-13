# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/micro.nix
#
# =====================================================================
# MICRO
# 
# Modern and intuitive terminal-based text editor
# =====================================================================

{ pkgs, lib, ... }:

let
  catppuccinMicro = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "micro";
    rev = "main";
    hash ="sha256-XbhUwRz21/XLkdOb6VOqLwzxWtehf6qRms0YcepNQ0s=
    ";
  };
in
{
  programs.micro = {
    enable = true;

    settings = {
      colorscheme = "catppuccin-mocha";
    };
  };

  home.sessionVariables = {
    MICRO_TRUECOLOR = "1";
    COLORTERM = "truecolor";
  };

  xdg.configFile."micro/colorschemes/catppuccin-mocha.micro".text =
    builtins.readFile "${catppuccinMicro}/themes/catppuccin-mocha.micro";
}