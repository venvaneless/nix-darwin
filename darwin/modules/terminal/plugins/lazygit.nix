# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/lazygit.nix
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