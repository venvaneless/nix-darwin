# /Users/ven/dotfiles/nix/shared/services/home-manager-standalone.nix
{ ... }:

{
  home.username = "ven";
  home.homeDirectory = "/Users/ven";
  home.stateVersion = "25.11";

  imports = [
    ../../shared/home/index.nix
    ../../darwin/modules/terminal/zsh.nix
  ];
}
