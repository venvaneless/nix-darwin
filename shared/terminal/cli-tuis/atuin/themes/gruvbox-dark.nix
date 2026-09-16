# shared/terminal/cli-tuis/atuin/themes/gruvbox-dark.nix
#
# =====================================================================
# ATUIN THEME: GRUVBOX DARK
#
# The Gruvbox Dark foreground and accent colours, matching WezTerm.
# Its file is written by options/cli/atuin/themes/helper.nix.
# =====================================================================

{ ... }:

{
  home.shared.cli.atuin.themes.gruvboxDark = {
    name = "gruvboxDark";
    atuinName = "gruvbox-dark";
    relativePath = "atuin/themes/gruvbox-dark.toml";

    colours = {
      AlertInfo = "#b8bb26";
      AlertWarn = "#fabd2f";
      AlertError = "#fb4934";
      Annotation = "#d3869b";
      Base = "#ebdbb2";
      Guidance = "#a89984";
      Important = "#fe8019";
      Title = "#83a598";
    };
  };
}
