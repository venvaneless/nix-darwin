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

  	# Install and enable Zoxide and integrate it with fish shell
    enable = true;
    enableFishIntegration = true;
  };

  home.sessionVariables._ZO_DATA_DIR =
  	# Keep existing user-owned data files in place
    "${config.xdg.dataHome}/zoxide";
}