# shared/terminal/cli-tuis/micro/themes/monokai-dark.nix
#
# =====================================================================
# MICRO: MONOKAI DARK THEME
#
# - Monokai Dark theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "monokai-dark"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.monokai-dark;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.monokai-dark.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Monokai Dark theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/monokai-dark.micro".text = ''
      color-link default "#D5D8D6,#1D0000"
      color-link comment "#75715E"
      color-link identifier "#66D9EF"
      color-link constant "#AE81FF"
      color-link constant.string "#E6DB74"
      color-link constant.string.char "#BDE6AD"
      color-link statement "#F92672"
      color-link preproc "#CB4B16"
      color-link type "#66D9EF"
      color-link special "#A6E22E"
      color-link underlined "#D33682"
      color-link error "bold #CB4B16"
      color-link todo "bold #D33682"
      color-link hlsearch "#1D0000,#E6DB74"
      color-link statusline "#282828,#F8F8F2"
      color-link indent-char "#505050,#282828"
      color-link line-number "#AAAAAA,#282828"
      color-link current-line-number "#AAAAAA,#1D0000"
      color-link diff-added "#00AF00"
      color-link diff-modified "#FFAF00"
      color-link diff-deleted "#D70000"
      color-link gutter-error "#CB4B16"
      color-link gutter-warning "#E6DB74"
      color-link cursor-line "#323232"
      color-link color-column "#323232"
    '';
  };
}
