# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/tmux.nix
#
# =====================================================================
# TMUX
#
# Terminal multiplexer with a user-scoped Home Manager configuration
# =====================================================================

{ ... }:

{
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
}
