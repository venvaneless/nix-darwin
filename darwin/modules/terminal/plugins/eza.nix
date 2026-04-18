# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/eza.nix
#
# ZSH: BAT
# =========================
# A modern replacement for ls

{ ... }:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };
}