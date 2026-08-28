# shared/terminal/cli-tuis/micro/themes/geany.nix
#
# =====================================================================
# MICRO: GEANY THEME
#
# - Geany theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "geany"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.geany;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.geany.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Geany theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/geany.micro".text = ''
      #Geany
      color-link comment "red"
      color-link constant "default"
      color-link constant.string "bold yellow"
      color-link identifier "default"
      color-link preproc "cyan"
      color-link special "blue"
      color-link statement "blue"
      color-link symbol "default"
      color-link symbol.tag "bold blue"
      color-link type "blue"
      color-link type.extended "default"
      color-link error "red"
      color-link todo "bold cyan"
      color-link hlsearch "black,brightcyan"
      color-link indent-char "bold black"
      color-link line-number ""
      color-link current-line-number ""
      color-link statusline "black,white"
      color-link tabbar "black,white"
      color-link color-column "bold geren"
      color-link diff-added "green"
      color-link diff-modified "yellow"
      color-link diff-deleted "red"
      color-link gutter-error ",red"
      color-link gutter-warning "red"
    '';
  };
}
