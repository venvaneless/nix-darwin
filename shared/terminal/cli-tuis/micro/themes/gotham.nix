# shared/terminal/cli-tuis/micro/themes/gotham.nix
#
# =====================================================================
# MICRO: GOTHAM THEME
#
# - Gotham theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "gotham"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.gotham;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.gotham.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Gotham theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/gotham.micro".text = ''
      color-link default "#99D1CE,#0C1014"
      color-link comment "#245361,#0C1014"
      color-link identifier "#599CAB,#0C1014"
      color-link constant "#D26937,#0C1014"
      color-link constant.string "#2AA889,#0C1014"
      color-link constant.string.char "#D3EBE9,#0C1014"
      color-link statement "#599CAB,#0C1014"
      color-link preproc "#C23127,#0C1014"
      color-link type "#D26937,#0C1014"
      color-link special "#D26937,#0C1014"
      color-link underlined "#EDB443,#0C1014"
      color-link error "bold #C23127,#0C1014"
      color-link todo "bold #888CA6,#0C1014"
      color-link hlsearch "#091F2E,#EDB443"
      color-link statusline "#091F2E,#599CAB"
      color-link indent-char "#505050,#0C1014"
      color-link line-number "#245361,#11151C"
      color-link current-line-number "#599CAB,#11151C"
      color-link diff-added "#00AF00"
      color-link diff-modified "#FFAF00"
      color-link diff-deleted "#D70000"
      color-link gutter-error "#C23127,#11151C"
      color-link gutter-warning "#EDB443,#11151C"
      color-link cursor-line "#091F2E"
      color-link color-column "#11151C"
      color-link symbol "#99D1CE,#0C1014"
    '';
  };
}
