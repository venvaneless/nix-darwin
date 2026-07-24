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
    enable = true;
    mouse = true;
    keyMode = "vi";
    sensibleOnTop = true;
    historyLimit = 50000;
    terminal = "screen-256color";
  };
}
