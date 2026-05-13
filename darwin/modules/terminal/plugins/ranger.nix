# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/modules/ranger.nix
#
# =====================================================================
# RANGER
# 
# Modern terminal-based file browser
# =====================================================================

{ ... }:

{
  programs.fish.shellAliases = {
    rr = "ranger";
  };
}