{ pkgs, ... }:

{
  home.packages = [ pkgs.mcfly ];

  programs.zsh.initExtraConfig = ''
    # MCFLY: smart history
    eval "$(mcfly init zsh)"
  '';
}
