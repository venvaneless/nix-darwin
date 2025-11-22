# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh/zsh/starship.nix
#
# ZSH: STARSHIP PROMPT
# ============================================================

{ ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}