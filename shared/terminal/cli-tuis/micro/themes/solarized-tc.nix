# shared/terminal/cli-tuis/micro/themes/solarized-tc.nix
#
# =====================================================================
# MICRO: SOLARIZED TC THEME
#
# - Solarized TC theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "solarized-tc"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.solarized-tc;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.solarized-tc.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Solarized TC theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/solarized-tc.micro".text = ''
      color-link default "#839496,#002833"
      color-link comment "#586E75,#002833"
      color-link identifier "#268BD2,#002833"
      color-link constant "#2AA198,#002833"
      color-link constant.specialChar "#DC322F,#002833"
      color-link statement "#859900,#002833"
      color-link symbol "#859900,#002833"
      color-link preproc "#CB4B16,#002833"
      color-link type "#B58900,#002833"
      color-link special "#268BD2,#002833"
      color-link underlined "#D33682,#002833"
      color-link error "bold #CB4B16,#002833"
      color-link todo "bold #D33682,#002833"
      color-link hlsearch "#002833,#B58900"
      color-link statusline "#003541,#839496"
      color-link tabbar "#003541,#839496"
      color-link indent-char "#003541,#002833"
      color-link line-number "#586E75,#003541"
      color-link current-line-number "#586E75,#002833"
      color-link diff-added "#00AF00"
      color-link diff-modified "#FFAF00"
      color-link diff-deleted "#D70000"
      color-link gutter-error "#003541,#CB4B16"
      color-link gutter-warning "#CB4B16,#002833"
      color-link cursor-line "#003541"
      color-link color-column "#003541"
      color-link type.extended "#839496,#002833"
      color-link symbol.brackets "#839496,#002833"
    '';
  };
}
