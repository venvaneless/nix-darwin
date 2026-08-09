# shared/terminal/cli-tuis/yazi.nix
#
# =====================================================================
# YAZI
#
# Terminal file manager with Fish integration
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.yazi;
in
{
  options.ven.features.terminal.cliTuis.yazi.enable = lib.mkEnableOption "Yazi terminal file manager";

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      # Install and enable Yazi and integrate it with fish shell
      enable = true;
      enableFishIntegration = true;

      # Set the name of the shell wrapper script to open Yazi
      shellWrapperName = "yy";
    };
  };
}
