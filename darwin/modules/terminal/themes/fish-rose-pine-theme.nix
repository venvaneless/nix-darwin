# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/themes/fish-rose-pine-theme.nix

{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.terminal.fish.theme == "rose-pine") {
    programs.fish.plugins = [
      {
      	# Name of the theme
        name = "rose-pine";

        # Download the theme from Github
        src = pkgs.fetchFromGitHub {

          # GitHub repository information
          owner = "rose-pine";
          repo = "fish";
          rev = "main";
          hash = "sha256-3heI6nhItw5WfKGQT1FRQKfv+lONyn+DzwYjYqJjzLE=";
        };
      }
    ];
  };
}