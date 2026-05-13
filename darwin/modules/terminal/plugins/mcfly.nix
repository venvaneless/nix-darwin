# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/mcfly.nix
# 
# =====================================================================
# MC-FLY
# 
# Fly through your shell history
# =====================================================================

{ pkgs, ... }:

{
  home.packages = [ pkgs.mcfly ];

  programs.zsh.initContent = ''
    eval "$(mcfly init zsh)"
  '';
}
