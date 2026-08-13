# shared/terminal/cli-tuis/starship.nix
#
# =====================================================================
# STARSHIP
#
# Cross-shell prompt for astronauts
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.starship;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Starship's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.starship.enable directly.
  starship = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    starship.enable && ((isDarwin && starship.installOn.darwin) || (isLinux && starship.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.starship.enable = lib.mkEnableOption "Starship shell prompt";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.starship.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
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
    })
  ];
}
