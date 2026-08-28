# shared/terminal/cli-tuis/micro/themes/sunny-day.nix
#
# =====================================================================
# MICRO: SUNNY DAY THEME
#
# - Sunny Day theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "sunny-day"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.sunny-day;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.sunny-day.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Sunny Day theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/sunny-day.micro".text = ''
      color-link default "0,230"
      color-link comment "244"
      color-link constant.string "17"
      color-link constant "88"
      color-link identifier "22"
      color-link statement "0,230"
      color-link symbol "89"
      color-link preproc "22"
      color-link type "88"
      color-link special "22"
      color-link underlined "61,230"
      color-link error "88"
      color-link todo "210"
      color-link hlsearch "0,253"
      color-link statusline "233,229"
      color-link tabbar "233,229"
      color-link indent-char "229"
      color-link line-number "244"
      color-link diff-added "34"
      color-link diff-modified "214"
      color-link diff-deleted "160"
      color-link gutter-error "88"
      color-link gutter-warning "88"
      color-link cursor-line "229"
      #color-link color-column "196"
      color-link current-line-number "246"
    '';
  };
}
