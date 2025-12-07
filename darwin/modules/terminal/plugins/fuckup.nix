{ pkgs, ... }:

{
  home.packages = [ pkgs.fuckup ];

  programs.zsh.initScripts = ''
    # FUCKUP: fix last command (thefuck replacement)
    eval "$(fuckup --alias)"
  '';
}
