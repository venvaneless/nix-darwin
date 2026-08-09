# shared/terminal/cli-tuis/delta.nix
#
# =====================================================================
# DELTA
#
# Syntax-highlighting pager for git and diff output
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.delta;
in
{
  options.ven.features.terminal.cliTuis.delta.enable =
    lib.mkEnableOption "Delta syntax-highlighting pager";

  config = lib.mkIf cfg.enable {
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
  };
}
