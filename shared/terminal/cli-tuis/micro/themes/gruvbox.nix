# shared/terminal/cli-tuis/micro/themes/gruvbox.nix
#
# =====================================================================
# MICRO: GRUVBOX THEME
#
# - Preserves the current custom Gruvbox Micro theme from micro.zip
# - Selected directly in ../micro.nix with selectedTheme = "gruvbox"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.gruvbox;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.gruvbox.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Gruvbox theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/gruvbox.micro".text = ''
      color-link default "223,235"
      color-link comment "243,235"
      color-link constant "175,235"
      color-link constant.string "142,235"
      color-link identifier "109,235"
      color-link statement "124,235"
      color-link symbol "124,235"
      color-link preproc "72,235"
      color-link type "214,235"
      color-link special "172,235"
      color-link underlined "underline 109,235"
      color-link error "235,124"
      color-link todo "bold 223,235"
      color-link hlsearch "235,214"
      color-link diff-added "34"
      color-link diff-modified "214"
      color-link diff-deleted "160"
      color-link line-number "243,237"
      color-link current-line-number "172,235"
      color-link cursor-line "237"
      color-link color-column "237"
      color-link statusline "223,237"
      color-link tabbar "223,237"
    '';
  };
}
