# shared/terminal/cli-tuis/micro/themes/gruvbox-tc.nix
#
# =====================================================================
# MICRO: GRUVBOX TC THEME
#
# - Gruvbox TC theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "gruvbox-tc"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.gruvbox-tc;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.gruvbox-tc.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Gruvbox TC theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/gruvbox-tc.micro".text = ''
      color-link default "#ebdbb2,#282828"
      color-link comment "#928374,#282828"
      color-link symbol "#d79921,#282828"
      color-link constant "#d3869b,#282828"
      color-link constant.string "#b8bb26,#282828"
      color-link constant.string.char "#b8bb26,#282828"
      color-link identifier "#8ec07c,#282828"
      color-link statement "#fb4934,#282828"
      color-link preproc "#fb4934,235"
      color-link type "#fb4934,#282828"
      color-link special "#d79921,#282828"
      color-link underlined "underline #458588,#282828"
      color-link error "#9d0006,#282828"
      color-link todo "bold #ebdbb2,#282828"
      color-link hlsearch "#282828,#fabd2f"
      color-link diff-added "#00AF00"
      color-link diff-modified "#FFAF00"
      color-link diff-deleted "#D70000"
      color-link gutter-error "#fb4934,#282828"
      color-link gutter-warning "#d79921,#282828"
      color-link line-number "#665c54,#3c3836"
      color-link current-line-number "#d79921,#282828"
      color-link cursor-line "#3c3836"
      color-link color-column "#79740e"
      color-link statusline "#ebdbb2,#665c54"
      color-link tabbar "#ebdbb2,#665c54"
    '';
  };
}
