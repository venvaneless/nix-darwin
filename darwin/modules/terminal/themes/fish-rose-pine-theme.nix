# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/themes/fish-rose-pine-theme.nix

{ pkgs, ... }:

{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.terminal.fish.theme == "rose-pine") {
    programs.fish.plugins = [
      {
        name = "rose-pine";
        src = pkgs.fetchFromGitHub {
          owner = "rose-pine";
          repo = "fish";
          rev = "main";
          hash = "sha256-3heI6nhItw5WfKGQT1FRQKfv+lONyn+DzwYjYqJjzLE=";
        };
      }
    ];
  };
}