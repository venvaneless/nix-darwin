# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/thefuck.nix
#
# ZSH: THEFUCK
# ============================================================

{ pkgs, ... }:

{
  home.packages = [
    pkgs.thefuck
  ];

  programs.zsh.initContent = ''
    eval "$(${pkgs.thefuck}/bin/thefuck --alias)"
  '';
}
