# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/yazi.nix
#
# ZSH: YAZI
# =========================
# Enables Yazi and shell integration for directory jumping on exit.

{ ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
}