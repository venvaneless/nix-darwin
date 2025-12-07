{ pkgs, ... }:

{
  home.packages = [ pkgs.mcfly ];

  programs.zsh.initScripts = [
    { name = "mcfly"; text = ''eval "$(mcfly init zsh)"''; }
  ];
}
