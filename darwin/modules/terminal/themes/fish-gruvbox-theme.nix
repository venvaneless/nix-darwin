# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/themes/fish-gruvbox-theme.nix

{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.terminal.fish.theme == "gruvbox") {
    programs.fish.plugins = [
      {
        name = "gruvbox";
        src = pkgs.fishPlugins.gruvbox.src;
      }
    ];

    programs.fish.interactiveShellInit = ''
      theme_gruvbox dark medium
    '';
  };
}