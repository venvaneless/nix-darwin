# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh/zsh/thefuck.nix
#
# ZSH: THEFUCK
# ============================================================

{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.thefuck
  ];

  programs.zsh.initExtra = ''
    eval "$(thefuck --alias)"
  '';
}
