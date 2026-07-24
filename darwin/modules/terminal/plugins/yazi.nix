# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/yazi.nix
#
# =====================================================================
# YAZI
#
# Terminal file manager with Fish integration
# =====================================================================

{ ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "yy";
  };
}
