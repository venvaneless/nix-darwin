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
  	# Install and enable Yazi and integrate it with fish shell
    enable = true;
    enableFishIntegration = true;

    # Set the name of the shell wrapper script to open Yazi
    shellWrapperName = "yy";
  };
}
