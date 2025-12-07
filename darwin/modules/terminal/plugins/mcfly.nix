{ pkgs, ... }:

{
  home.packages = [ pkgs.mcfly ];

  programs.zsh.initContent = ''
    eval "$(mcfly init zsh)"
  '';
}
