# shared/terminal/cli-tuis/yazi.nix
#
# =====================================================================
# YAZI
#
# Terminal file manager with Fish integration
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.yazi;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Yazi's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.yazi.enable directly.
  yazi = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  enabledForCurrentSystem =
    yazi.enable && ((isDarwin && yazi.installOn.darwin) || (isLinux && yazi.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.yazi.enable = lib.mkEnableOption "Yazi terminal file manager";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.yazi.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
    programs.yazi = {
      # Install and enable Yazi and integrate it with fish shell
      enable = true;
      enableFishIntegration = true;

      # Set the name of the shell wrapper script to open Yazi
      shellWrapperName = "yy";
    };
    })
  ];
}
