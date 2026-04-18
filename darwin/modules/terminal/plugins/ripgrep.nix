# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/ripgrep.nix
#
# ZSH: DELTA
# =========================
# Utility that combines the usability of The Silver Searcher with the raw speed of grep

{ ... }:

{
  programs.ripgrep = {
    enable = true;
    enableGitIntegration = true;
  };
}
