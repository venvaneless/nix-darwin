# shared/terminal/cli-tuis/tmux.nix
#
# =====================================================================
# TMUX
#
# Terminal multiplexer with a user-scoped Home Manager configuration
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.tmux;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Tmux's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.tmux.enable directly.
  tmux = {
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
    tmux.enable && ((isDarwin && tmux.installOn.darwin) || (isLinux && tmux.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.tmux.enable = lib.mkEnableOption "Tmux terminal multiplexer";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.tmux.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
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
    })
  ];
}
