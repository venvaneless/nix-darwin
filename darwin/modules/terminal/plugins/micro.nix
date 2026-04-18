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
    hash = lib.fakeHash;
  };
in
{
  programs.micro = {
    enable = true;

    settings = {
      colorscheme = "catppuccin-mocha";
    };
  };

  xdg.configFile."micro/colorschemes/catppuccin-mocha.micro".text =
    builtins.readFile "${catppuccinMicro}/themes/catppuccin-mocha.micro";
}