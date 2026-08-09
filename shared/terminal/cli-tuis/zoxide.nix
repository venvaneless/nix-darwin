# shared/terminal/cli-tuis/zoxide.nix
#
# =====================================================================
# ZOXIDE
#
# Shell extension to navigate your filesystem faster
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.zoxide;
in
{
  options.ven.features.terminal.cliTuis.zoxide.enable =
    lib.mkEnableOption "Zoxide directory navigation";

  config = lib.mkIf cfg.enable {
    programs.zoxide = {

      # Install and enable Zoxide and integrate it with fish shell
      enable = true;
      enableFishIntegration = true;
    };

    home.sessionVariables._ZO_DATA_DIR =
      # Keep existing user-owned data files in place
      "${config.xdg.dataHome}/zoxide";
  };
}
