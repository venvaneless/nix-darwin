# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/tmux-extras.nix
#
# ZSH: TMUX AUTOSTART
# =========================
# Automatically enters tmux for interactive local shells.

{ ... }:

{
  programs.zsh.initContent = ''
    if [[ -o interactive ]] && [[ -z "$TMUX" ]] && [[ -z "$SSH_CONNECTION" ]]; then
      exec tmux
    fi
  '';
}