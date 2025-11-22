# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh/zsh/starship.nix
#
# ZSH: STARSHIP PROMPT
# ============================================================

{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
