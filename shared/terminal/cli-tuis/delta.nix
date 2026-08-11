# shared/terminal/cli-tuis/delta.nix
#
# =====================================================================
# DELTA
#
# Syntax-highlighting pager for git and diff output
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.delta;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Delta's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.delta.enable directly.
  delta = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  enabledForCurrentSystem =
    delta.enable && ((isDarwin && delta.installOn.darwin) || (isLinux && delta.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.delta.enable =
    lib.mkEnableOption "Delta syntax-highlighting pager";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.delta.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
    programs.delta = {
      # Install delta and enable its Git integration
      enable = true;
      enableGitIntegration = true;

      # ---- OPTIONS ---- #
      options = {

        # Set syntax theme
        syntax-theme = "gruvbox-dark";

        # Set delta's navigation option
        navigate = true;

        # Enable line numbers
        line-numbers = true;

        # Enable side-by-side view
        side-by-side = true;

        # Optional dark mode setting
        dark = true;
      };
    };
    })
  ];
}
