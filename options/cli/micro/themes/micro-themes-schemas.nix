# options/cli/micro/themes/micro-themes-schemas.nix
#
# =====================================================================
# MICRO: THEME SCHEMAS
#
# Declarative index of enabled Micro colour scheme files managed by Nix.
# The registry in default.nix supplies the available themes; their individual
# enable switches determine the colorschemes.json entries.
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.cli.micro;

  themeRegistry = import ./.;

  themes = lib.mapAttrsToList
    (name: theme:
      lib.optionalString microCfg.themes.${name}.enable "${theme.themeName}.micro")
    themeRegistry;

  enabledThemes = lib.filter (theme: theme != "") themes;

  themesJson = builtins.toJSON enabledThemes;
in
{
  config = lib.mkIf microCfg.enabledForCurrentPlatform {
    xdg.configFile."micro/colorschemes.json".text = themesJson;
  };
}
