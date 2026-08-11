# shared/terminal/fish-themes.nix
#
# =====================================================================
# FISH: SHARED THEMES
# =====================================================================

{ lib, ... }:

{
  options = {
    terminal.fish.theme = lib.mkOption {
      type = lib.types.enum [
        "none"
        "rose-pine"
        "gruvbox"
      ];
      default = "gruvbox";
      description = "Fish syntax/theme plugin to use.";
    };
  };

  imports = [
    ./themes/fish-gruvbox-theme.nix
    ./themes/fish-rose-pine-theme.nix
  ];
}
