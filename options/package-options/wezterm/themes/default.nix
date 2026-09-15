# options/package-options/wezterm/themes/default.nix
#
# Declares all named theme knobs and renders only the selected theme.
# Palette values live in shared/terminal/wezterm/themes/.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  themeHelper = import ./helper.nix { inherit lib pkgs; };

  themes = [
    {
      name = "gruvbox";
      title = "Gruvbox";
      description = "Warm Gruvbox Dark (Gogh) colors and tab bar settings.";
      relativePath = ".config/wezterm/themes/gruvbox.lua";
    }
    {
      name = "nord";
      title = "Nord";
      description = "Cool Nord terminal, window frame, and tab bar colors.";
      relativePath = ".config/wezterm/themes/nord.lua";
    }
    {
      name = "nord-otto";
      title = "Nord Otto";
      description = "Nord-based Otto palette with its terminal and tab bar colors.";
      relativePath = ".config/wezterm/themes/nord-otto.lua";
    }
    {
      name = "otto";
      title = "Otto";
      description = "Otto terminal, window frame, and tab bar colors.";
      relativePath = ".config/wezterm/themes/otto.lua";
    }
  ];
in
{
  options.shared.terminal.wezterm.themes =
    themeHelper.themeSelectorOptions
    // lib.listToAttrs (
      map (theme: lib.nameValuePair theme.name (themeHelper.mkThemeOption theme)) themes
    );

  config = lib.mkMerge (map (theme: themeHelper.mkThemeConfig (theme // { inherit config; })) themes);
}
