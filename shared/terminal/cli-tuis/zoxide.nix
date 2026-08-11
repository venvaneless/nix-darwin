# shared/terminal/cli-tuis/zoxide.nix
#
# =====================================================================
# ZOXIDE
#
# Shell extension to navigate your filesystem faster
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.zoxide;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Zoxide's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.zoxide.enable directly.
  zoxide = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  enabledForCurrentSystem =
    zoxide.enable && ((isDarwin && zoxide.installOn.darwin) || (isLinux && zoxide.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.zoxide.enable =
    lib.mkEnableOption "Zoxide directory navigation";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.zoxide.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
    programs.zoxide = {

      # Install and enable Zoxide and integrate it with fish shell
      enable = true;
      enableFishIntegration = true;
    };

    home.sessionVariables._ZO_DATA_DIR =
      # Keep existing user-owned data files in place
      "${config.xdg.dataHome}/zoxide";
    })
  ];
}
