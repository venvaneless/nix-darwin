# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/starship.nix
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