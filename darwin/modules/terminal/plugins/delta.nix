# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/delta.nix
#
# ZSH: DELTA
# =========================
# Enables delta for Git diffs.

{ ... }:

{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
