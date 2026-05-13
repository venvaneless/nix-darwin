# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/zoxide.nix
# 
# =====================================================================
# ZOXIDE
# 
# Shell extension to navigate your filesystem faster
# =====================================================================

{ ... }:

{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}