# shared/terminal/cli-tuis/bat/bat.nix
#
# =====================================================================
# BAT
#
# Syntax-highlighting replacement for cat, used as:
# - The `cat` alias in shared/terminal/aliases/shell-aliases.nix
# - A general file viewer and pager
#
# Installation and settings are managed through Home Manager.
# Themes live in their own files. Select one directly below; bat imports
# and enables only that one module.
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.bat;

  # ---- THEME SELECTION ---- #
  # Change this value to select a different saved bat theme.
  selectedTheme = "gruvboxDark";

  # ---- AVAILABLE THEMES ---- #
  # Each custom theme remains separate, but only selectedTheme is imported.
  themeModules = {
    default = {
      module = null;
      option = null;
    };
    gruvboxDark = {
      module = ./bat-gruvbox.nix;
      option = "gruvbox";
    };
    rosePine = {
      module = ./bat-rose-pine.nix;
      option = "rosePine";
    };
  };

  selectedThemeConfig =
    if lib.hasAttr selectedTheme themeModules then
      themeModules.${selectedTheme}
    else
      throw ''
        bat: unknown selectedTheme "${selectedTheme}".
        Choose one of: ${lib.concatStringsSep ", " (lib.attrNames themeModules)}
      '';
in
{
  options.ven.features.terminal.cliTuis.bat.enable = lib.mkEnableOption "Bat file viewer";

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.bat = {
      enable = true;

      config = {
        # ---- APPEARANCE ---- #

        # The selected theme module overrides this built-in fallback.
        theme = lib.mkDefault "Monokai Extended";

        # Line numbers, Git change markers, and the file header.
        style = "numbers,changes,header";

        # Wrap long lines at the terminal width.
        wrap = "auto";

        # Keep bat's output plain when it is piped into another command.
        paging = "auto";
      };
      };
    })
    (lib.mkIf (cfg.enable && selectedThemeConfig.option != null) {
      # Only the selected theme module is imported and enabled.
      ven.features.terminal.cliTuis.bat.${selectedThemeConfig.option}.enable = true;
    })
  ];

  imports = lib.optional (selectedThemeConfig.module != null) selectedThemeConfig.module;
}
