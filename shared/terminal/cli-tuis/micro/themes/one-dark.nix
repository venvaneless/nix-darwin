# shared/terminal/cli-tuis/micro/themes/one-dark.nix
#
# =====================================================================
# MICRO: ONE DARK THEME
#
# - One Dark theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "one-dark"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.one-dark;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.one-dark.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the One Dark theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/one-dark.micro".text = ''
      color-link default "#ABB2BF,#21252C"
      color-link color-column "#282C34"
      color-link comment "#5C6370"
      color-link constant "#C678DD"
      color-link constant.number "#E5C07B"
      color-link constant.string "#98C379"
      color-link constant.string.char "#BDE6AD"
      color-link constant.specialChar "#DDF2A4"
      color-link current-line-number "#C6C6C6,#21252C"
      color-link cursor-line "#282C34"
      color-link divider "#ABB2BF"
      color-link error "#D2A8A1"
      color-link diff-added "#00AF00"
      color-link diff-modified "#FFAF00"
      color-link diff-deleted "#D70000"
      color-link gutter-error "#9B859D"
      color-link gutter-warning "#9B859D"
      color-link hlsearch "#21252C,#E5C07B"
      color-link identifier "#61AFEF"
      color-link identifier.class "#C678DD"
      color-link identifier.var "#C678DD"
      color-link indent-char "#515151"
      color-link line-number "#636D83,#282C34"
      color-link preproc "#E0C589"
      color-link special "#E0C589"
      color-link statement "#C678DD"
      color-link statusline "#282828,#ABB2BF"
      color-link symbol "#AC885B"
      color-link symbol.brackets "#ABB2BF"
      color-link symbol.operator "#C678DD"
      color-link symbol.tag "#AC885B"
      color-link tabbar "#F2F0EC,#2D2D2D"
      color-link todo "#8B98AB"
      color-link type "#66D9EF"
      color-link type.keyword "#C678DD"
      color-link underlined "#8996A8"
    '';
  };
}
