# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/lazygit.nix
#
# ZSH: LAZYGIT
# =========================
# Installs and enables Lazygit configuration support.

{ ... }:

{
  programs.lazygit = {
    enable = true;
  };
}