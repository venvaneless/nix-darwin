# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/fish-themes.nix

{ config, lib, pkgs, ... }:

let
  cfg = config.terminal.fish;
in
{
  options.terminal.fish.theme = lib.mkOption {
    type = lib.types.enum [ "none" "rose-pine" "gruvbox" ];
    default = "gruvbox";
    description = "Fish syntax/theme plugin to use.";
  };

  imports = [
    ./themes/fish-gruvbox-theme.nix
    ./themes/fish-rose-pine-theme.nix
  ];
}