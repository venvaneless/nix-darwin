# shared/terminal/cli-tuis/atuin/themes/catppuccin-mocha-mauve.nix
#
# =====================================================================
# ATUIN THEME: CATPPUCCIN MOCHA MAUVE
#
# The archived Catppuccin Mocha Mauve colours, kept for switching back.
# Its file is written by options/cli/atuin/themes/helper.nix.
# =====================================================================

{ ... }:

{
  home.shared.cli.atuin.themes.catppuccinMochaMauve = {
    name = "catppuccinMochaMauve";
    atuinName = "catppuccin-mocha-mauve";
    relativePath = "atuin/themes/catppuccin-mocha-mauve.toml";

    colours = {
      AlertInfo = "#a6e3a1";
      AlertWarn = "#fab387";
      AlertError = "#f38ba8";
      Annotation = "#cba6f7";
      Base = "#cdd6f4";
      Guidance = "#9399b2";
      Important = "#f38ba8";
      Title = "#cba6f7";
    };
  };
}
