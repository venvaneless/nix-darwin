# /Users/ven/dotfiles/nix/stable/darwin/modules/terminal/zsh/zsh/starship.nix
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