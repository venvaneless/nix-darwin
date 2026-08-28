# shared/terminal/cli-tuis/micro/themes/simple.nix
#
# =====================================================================
# MICRO: SIMPLE THEME
#
# - Simple theme for Micro
# - Selected directly in ../micro.nix with selectedTheme = "simple"
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;
  cfg = microCfg.themes.simple;
in
{
  options.ven.features.terminal.cliTuis.micro.themes.simple.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Simple theme selected in micro.nix.";
  };

  config = lib.mkIf (microCfg.enable && cfg.enable) {
    # Micro loads custom colour schemes from this XDG colourschemes directory.
    xdg.configFile."micro/colorschemes/simple.micro".text = ''
      color-link comment "blue"
      color-link constant "red"
      color-link identifier "cyan"
      color-link statement "yellow"
      color-link symbol "yellow"
      color-link preproc "magenta"
      color-link type "green"
      color-link special "magenta"
      color-link ignore "default"
      color-link error ",brightred"
      color-link todo ",brightyellow"
      color-link hlsearch "black,yellow"
      color-link indent-char "black"
      color-link line-number "yellow"
      color-link current-line-number "red"
      color-link diff-added "green"
      color-link diff-modified "yellow"
      color-link diff-deleted "red"
      color-link gutter-error ",red"
      color-link gutter-warning "red"
      #Cursor line causes readability issues. Disabled for now.
      #color-link cursor-line "white,black"
      color-link color-column "white"
      #No extended types. (bool in C)
      color-link type.extended "default"
      #No bracket highlighting.
      color-link symbol.brackets "default"
      #Color shebangs the comment color
      color-link preproc.shebang "comment"
    '';
  };
}
