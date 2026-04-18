# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/micro.nix
#
# =============================================================
# ZSH: MICRO
# Modern and intuitive terminal-based text editor
# =============================================================

{ pkgs, lib, ... }:

let
  catppuccinMicro = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "micro";
    rev = "main";
    hash = "sha256-Gm6ThktOLUR+KDs6f3s1WCgrw2TOKQ4tolVvVdCxnCM=";
  };
in
{
  programs.micro = {
    enable = true;

    settings = {
      colorscheme = "catppuccin-mocha";
    };
  };

  xdg.configFile."micro/colorschemes/catppuccin-mocha.micro".source =
    "${catppuccinMicro}/themes/catppuccin-mocha.micro";
}