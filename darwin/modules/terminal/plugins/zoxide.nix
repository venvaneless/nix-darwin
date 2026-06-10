# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/zoxide.nix
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