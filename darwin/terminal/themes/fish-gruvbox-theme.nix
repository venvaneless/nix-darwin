# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/themes/fish-gruvbox-theme.nix

{ config, lib, pkgs, ... }:

{
# Install and enable the Gruvbox theme for Fish shell
  config = lib.mkIf (config.terminal.fish.theme == "gruvbox") {
    programs.fish.plugins = [
      {
        name = "gruvbox";
        # Install the theme from the fishPlugins package set
        src = pkgs.fishPlugins.gruvbox.src;
      }
    ];

    # Set the Gruvbox theme for Fish shell
    programs.fish.interactiveShellInit = ''
      theme_gruvbox dark medium
    '';
  };
}