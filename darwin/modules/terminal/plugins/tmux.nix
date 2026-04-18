# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/tmux.nix
#
# =============================================================
# TMUX
# Enables tmux with a sane default config
# =============================================================

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