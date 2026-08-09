# shared/terminal/cli-tuis/tmux.nix
#
# =====================================================================
# TMUX
#
# Terminal multiplexer with a user-scoped Home Manager configuration
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.tmux;
in
{
  options.ven.features.terminal.cliTuis.tmux.enable = lib.mkEnableOption "Tmux terminal multiplexer";

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      # Install tmux and enable it
      enable = true;

      # Enable mouse support
      mouse = true;

      # Set the default key mode to vi
      keyMode = "vi";

      # Keep the status bar on top of the terminal window
      sensibleOnTop = true;

      # Set the history limit to x lines
      historyLimit = 50000;

      # Set the default terminal to 256-color
      terminal = "screen-256color";
    };
  };
}
