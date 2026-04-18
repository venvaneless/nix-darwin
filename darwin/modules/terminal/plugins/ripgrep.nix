# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/ripgrep.nix
#
# RIPGREP
# =============================================================
# Utility that combines the usability of The Silver Searcher
# with the raw speed of grep
# =============================================================

{ ... }:

{
  programs.ripgrep = {
    enable = true;
  };
}
