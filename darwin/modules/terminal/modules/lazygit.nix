# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/modules/lazygit.nix
#
# =====================================================================
# LAZYGIT
# 
# Simple terminal UI for git commands
# =====================================================================

{ ... }:

{
  programs.fish.shellAliases = {
    # --- l-g -> lazygit
    # Open lazygit.
    l-g = "lazygit";
  };
}