# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/bat.nix
# 
# =====================================================================
# BAT
# 
# Cat clone with syntax highlighting and Git integration
# =====================================================================

{ ... }:

{
  # Installs Bat without replacing the existing files under ~/.config/bat.
  programs.bat.enable = true;

  programs.fish.shellAliases = {
    # --- cat -> bat
    # Use bat instead of cat for syntax highlighting.
    cat = "bat";
  };
}
