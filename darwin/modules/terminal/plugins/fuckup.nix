{ pkgs, ... }:

{
  home.packages = [ pkgs.fuckup ];

  programs.zsh.initExtraConfig = ''
    # FUCKUP: fix last command (thefuck replacement)
    eval "$(fuckup --alias)"
  '';
}
