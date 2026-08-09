# shared/terminal/cli-tuis/starship.nix
#
# =====================================================================
# STARSHIP
#
# Cross-shell prompt for astronauts
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.starship;
in
{
  options.ven.features.terminal.cliTuis.starship.enable = lib.mkEnableOption "Starship shell prompt";

  config = lib.mkIf cfg.enable {
    programs.starship = {

      # Install and enable Starship and integrate it with fish shell
      enable = true;
      enableFishIntegration = true;
    };

    programs.fish.shellInit = ''
      # ---------- Starship paths ---------- #
      # Set the path to the Starship config file and cache directory
      set -gx STARSHIP_CONFIG "${config.home.homeDirectory}/.config/starship.toml"
      set -gx STARSHIP_CACHE "${config.home.homeDirectory}/.config/.cache/"
    '';
  };
}
