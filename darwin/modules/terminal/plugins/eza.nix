# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/bat.nix
#
# ZSH: BAT
# =========================
# Cat clone with syntax highlighting and Git integration

{ ... }:

{
  programs.eza = {
    enable = true;
  };
}