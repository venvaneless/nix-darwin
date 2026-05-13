# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/modules/bat.nix
# 
# =====================================================================
# BAT
# 
# Cat clone with syntax highlighting and Git integration
# Includes bat-extras helper tools
# =====================================================================

{ ... }:

{
  programs.fish.shellAliases = {
    # --- cat -> bat
    # Use bat instead of cat for syntax highlighting.
    cat = "bat";
  };
}