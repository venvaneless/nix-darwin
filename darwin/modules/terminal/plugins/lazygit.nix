# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/lazygit.nix
#
# =============================================================
# LAZYGIT
# Installs and enables Lazygit configuration support.
# =============================================================

{ ... }:

{
  programs.lazygit = {
    enable = true;
  };
}