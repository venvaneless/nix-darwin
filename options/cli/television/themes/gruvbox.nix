# options/cli/television/themes/gruvbox.nix
#
# =====================================================================
# TELEVISION THEME: GRUVBOX
#
# - Identity, output file, and colour values for the Gruvbox Television theme
# - Knobs are declared and rendered by ./default.nix
# - Selected in shared/terminal/cli-tuis/default.nix with home.shared.cli.television.uiTheme = "gruvbox"
# - Uses the same Gruvbox Dark colours as the local WezTerm palette
# =====================================================================

{ ... }:
{
  config.home.shared.cli.television.themes.gruvbox = {
    name = "gruvbox";
    title = "Gruvbox";
    description = "Gruvbox Dark colours matching the WezTerm palette.";

    # TOML file this theme is written to. Its file name (ven-gruvbox) is
    # what config.toml selects.
    relativePath = ".config/television/themes/ven-gruvbox.toml";

    general = {
      background = "#282828";
      borderFg = "#665c54";
      textFg = "#ebdbb2";
      dimmedTextFg = "#a89984";
    };

    input = {
      textFg = "#fb4934";
      resultCountFg = "#cc241d";
    };

    results = {
      nameFg = "#83a598";
      lineNumberFg = "#fabd2f";
      valueFg = "#ebdbb2";
      selectionFg = "#282828";
      selectionBg = "#d79921";
      matchFg = "#fb4934";
    };

    preview = {
      titleFg = "#b8bb26";
    };

    modes = {
      channel = {
        fg = "#282828";
        bg = "#b16286";
      };

      remoteControl = {
        fg = "#282828";
        bg = "#8ec07c";
      };

      actionPicker = {
        fg = "#282828";
        bg = "#83a598";
      };
    };
  };
}
