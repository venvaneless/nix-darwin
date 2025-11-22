# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh/zsh/fzf.nix
#
# ZSH: FZF INTEGRATION
# ============================================================

{ config, pkgs, ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
