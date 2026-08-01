# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/delta.nix
#
# =====================================================================
# DELTA
#
# Syntax-highlighting pager for git and diff output
# =====================================================================

{ ... }:

{
  programs.delta = {
  	# Install delta and enable its Git integration
    enable = true;
    enableGitIntegration = true;

    # ---- OPTIONS ---- #
    options = {

      # Set syntax theme
      syntax-theme = "gruvbox-dark";

      # Set delta's navigation option
      navigate = true;

      # Enable line numbers 
      line-numbers = true;

      # Enable side-by-side view
      side-by-side = true;

      # Optional dark mode setting
      dark = true;
    };
  };
}