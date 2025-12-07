{ pkgs, ... }:

{
  home.packages = [ pkgs.fuckup ];

  programs.zsh.initExtra = ''
    # FUCKUP: fix last command (thefuck replacement)
    eval "$(fuckup --alias)"
  '';
}
