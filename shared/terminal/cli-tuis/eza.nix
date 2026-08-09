# shared/terminal/cli-tuis/eza.nix
#
# =====================================================================
# EZA
#
# Modern, maintained replacement for ls
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.eza;
in
{
  options.ven.features.terminal.cliTuis.eza.enable = lib.mkEnableOption "Eza file listing";

  config = lib.mkIf cfg.enable {
    programs.eza = {
      # Install and enable eza and integrate it with fish shell
      enable = true;
      enableFishIntegration = true;

      # Enable icons
      icons = "always";

      # Enable colors
      colors = "always";

      # Enable git
      git = true;
    };

    # Keep existing user-owned theme and supporting files in place
    home.sessionVariables.EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
  };
}
