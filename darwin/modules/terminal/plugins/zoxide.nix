# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/zoxide.nix
#
# ZSH: ZOXIDE
# =========================
# Enables smarter directory jumping for Zsh.

{ ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}