# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/zoxide.nix
# 
# =====================================================================
# ZOXIDE
# 
# Shell extension to navigate your filesystem faster
# =====================================================================

{ config, ... }:

{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  home.sessionVariables._ZO_DATA_DIR =
    "${config.xdg.dataHome}/zoxide";
}