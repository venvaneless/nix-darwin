{ pkgs, ... }:

{
  home.packages = [ pkgs.mcfly ];

  programs.zsh.initScripts = ''
    eval "$(mcfly init zsh)"
  '';
}
