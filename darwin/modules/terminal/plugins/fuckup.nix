{ pkgs, ... }:

{
  home.packages = [ pkgs.fuckup ];

  programs.zsh.initScripts = [
    { name = "fuckup"; text = "eval \"$(fuckup --alias)\""; }
  ];
}
