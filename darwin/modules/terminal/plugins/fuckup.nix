{ pkgs, ... }:

{
  home.packages = [ pkgs.fuckup ];

  programs.zsh.initContent = [
    { name = "fuckup"; text = "eval \"$(fuckup --alias)\""; }
  ];
}
