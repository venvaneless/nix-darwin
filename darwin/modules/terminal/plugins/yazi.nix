# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/yazi.nix
#
# =============================================================
# YAZI
# Blazing fast terminal file manager written in Rust, based on async I/O
# =============================================================

{ ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
}