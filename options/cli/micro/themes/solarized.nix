# options/cli/micro/themes/solarized.nix
#
# =====================================================================
# MICRO: SOLARIZED THEME
#
# - Solarized theme for Micro
# - Selected directly in ../default.nix with selectedTheme = "solarized"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.home.shared.cli.micro;
  cfg = microCfg.themes.solarized;
in
{
  options.home.shared.cli.micro.themes.solarized.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Solarized theme selected in default.nix.";
  };

  config = lib.mkIf (microCfg.enabledForCurrentPlatform && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/solarized.micro".text = ''
      color-link comment "bold brightgreen"
      color-link constant "cyan"
      color-link constant.specialChar "red"
      color-link identifier "blue"
      color-link statement "green"
      color-link symbol "green"
      color-link preproc "brightred"
      color-link type "yellow"
      color-link special "blue"
      color-link underlined "magenta"
      color-link error "bold brightred"
      color-link todo "bold magenta"
      color-link hlsearch "black,yellow"
      color-link statusline "black,brightblue"
      color-link tabbar "black,brightblue"
      color-link indent-char "black"
      color-link line-number "bold brightgreen,black"
      color-link current-line-number "bold brightgreen,default"
      color-link diff-added "green"
      color-link diff-modified "yellow"
      color-link diff-deleted "red"
      color-link gutter-error "black,brightred"
      color-link gutter-warning "brightred,default"
      color-link cursor-line "black"
      color-link color-column "black"
      color-link type.extended "default"
      color-link symbol.brackets "default"
    '';
  };
}
