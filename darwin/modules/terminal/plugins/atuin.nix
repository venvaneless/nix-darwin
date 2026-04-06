# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/atuin.nix
#
# ZSH: ATUIN
# =========================
# Enables Atuin and hooks it into Zsh history search.

{ ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };
}