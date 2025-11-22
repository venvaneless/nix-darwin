# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh/zsh/asdf.nix
#
# ZSH: ASDF VERSION MANAGER
# ============================================================

{ config, pkgs, ... }:

{
  # Install asdf itself via Nix
  home.packages = [
    pkgs.asdf-vm
  ];

  programs.zsh.initExtra = ''
    # ASDF initialization
    if [ -d "$HOME/.asdf" ]; then
      . "$HOME/.asdf/asdf.sh"
      . "$HOME/.asdf/completions/asdf.bash" 2>/dev/null || true
    fi
  '';
}
