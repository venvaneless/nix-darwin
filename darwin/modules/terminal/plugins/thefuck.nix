# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh/zsh/thefuck.nix
#
# ZSH: THEFUCK
# ============================================================

{ pkgs, ... }:

{
  home.packages = [
    pkgs.thefuck
  ];

  programs.zsh.initExtra = ''
    eval "$(${pkgs.thefuck}/bin/thefuck --alias)"
  '';
}
