# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/fish-themes.nix

{ config, lib, pkgs, ... }:

let
  # Access the fish configuration in the terminal module
  cfg = config.terminal.fish;
in
{
  # Get the Fish theme configuration from the terminal module
  options.terminal.fish.theme = lib.mkOption {
  	# Define the type of the option as an enumeration of available themes
    type = lib.types.enum [ "none" "rose-pine" "gruvbox" ];

    # Set the default theme
    default = "gruvbox";
    description = "Fish syntax/theme plugin to use.";
  };

  # Import the theme modules for Fish shell
  imports = [
    ./themes/fish-gruvbox-theme.nix
    ./themes/fish-rose-pine-theme.nix
  ];
}