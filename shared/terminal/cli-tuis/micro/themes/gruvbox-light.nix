# shared/terminal/cli-tuis/micro/themes/gruvbox-light.nix
#
# =====================================================================
# MICRO: GRUVBOX LIGHT THEME
#
# - Gruvbox-Light theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "gruvbox-light"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.gruvbox-light;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.gruvbox-light.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Gruvbox-Light theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/gruvbox-light.micro".text = ''
      color-link default "223,229"
      color-link comment "243,229"
      color-link constant "175,229"
      color-link constant.string "142,229"
      color-link identifier "109,229"
      color-link statement "124,229"
      color-link symbol "124,229"
      color-link preproc "72,229"
      color-link type "214,229"
      color-link special "172,229"
      color-link underlined "underline 109,229"
      color-link error "235,124"
      color-link todo "bold 223,229"
      color-link hlsearch "235,214"
      color-link diff-added "34"
      color-link diff-modified "214"
      color-link diff-deleted "160"
      color-link line-number "243,237"
      color-link current-line-number "172,229"
      color-link cursor-line "229"
      color-link color-column "237"
      color-link statusline "223,237"
      color-link tabbar "223,237"
    '';
  };
}
