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
    enable = true;
    enableGitIntegration = true;

    options = {
      syntax-theme = "gruvbox-dark";
      navigate = true;
      line-numbers = true;
      side-by-side = true;

      # Optional
      dark = true;
    };
  };
}