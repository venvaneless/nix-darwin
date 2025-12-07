{ pkgs, ... }:

{
  home.packages = [ pkgs.mcfly ];

  programs.zsh.initExtra = ''
    eval "$(mcfly init zsh)"
  '';
}
