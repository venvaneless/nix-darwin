# shared/terminal/cli-tuis/eza/eza.nix
#
# =====================================================================
# EZA
#
# Modern, maintained replacement for ls
#
# Installation and settings are managed through Home Manager.
# Each theme lives in its own eza-<name>.nix file. Select one theme
# directly below; eza imports and enables only that one module.
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.eza;

  # ---- THEME SELECTION ---- #
  # Select the active theme here. Change this value to one of the keys in
  # themeModules below; only that theme module generates theme.yml.
  selectedTheme = "gruvboxDark";

  # ---- AVAILABLE THEMES ---- #
  # Each palette remains separate, but only selectedTheme is imported.
  themeModules = {
    black = ./themes/black.nix;
    catppuccinFrappe = ./themes/catppuccin-frappe.nix;
    catppuccinLatte = ./themes/catppuccin-latte.nix;
    catppuccinMacchiato = ./themes/catppuccin-macchiato.nix;
    catppuccinMine = ./themes/catppuccin-mine.nix;
    catppuccinMocha = ./themes/catppuccin-mocha.nix;
    default = ./themes/default-theme.nix;
    dracula = ./themes/dracula.nix;
    frosty = ./themes/frosty.nix;
    gruvboxDark = ./themes/gruvbox-dark.nix;
    gruvboxLight = ./themes/gruvbox-light.nix;
    oneDark = ./themes/one-dark.nix;
    rosePine = ./themes/rose-pine.nix;
    rosePineDawn = ./themes/rose-pine-dawn.nix;
    rosePineMoon = ./themes/rose-pine-moon.nix;
    solarizedDark = ./themes/solarized-dark.nix;
    tokyonight = ./themes/tokyonight.nix;
    white = ./themes/white.nix;
    yahddyypCatppuccin = ./themes/yahddyyp-catppuccin.nix;
  };

  selectedThemeModule =
    if lib.hasAttr selectedTheme themeModules then
      themeModules.${selectedTheme}
    else
      throw ''
        eza: unknown selectedTheme "${selectedTheme}".
        Choose one of: ${lib.concatStringsSep ", " (lib.attrNames themeModules)}
      '';
in
{
  options.ven.features.terminal.cliTuis.eza.enable = lib.mkEnableOption "Eza file listing";

  config = lib.mkIf cfg.enable {
    # ---- ACTIVE THEME ---- #
    # The selected module exposes this internal switch. Because it is the
    # only imported theme module, a second eza palette cannot be enabled.
    ven.features.terminal.cliTuis.eza.themes.${selectedTheme}.enable = true;

    programs.eza = {
      # Install and enable eza
      enable = true;

      # ---- SHELL INTEGRATION ---- #
      # Provides the ls/ll/la/lt/lla aliases. Fish is the only configured
      # shell here; the rest stay off so no stray aliases are generated.
      enableFishIntegration = true;

      # ---- OUTPUT ---- #

      # Enable icons
      icons = "always";

      # Enable colors
      colors = "always";

      # Enable git
      git = true;

      # Extra flags appended to every eza invocation.
      # Examples: "--group-directories-first" "--header" "--octal-permissions"
      extraOptions = [ ];
    };

    # Tell eza where Home Manager writes the selected theme.yml file.
    home.sessionVariables.EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
  };

  imports = [
    # ---- THEMES ---- #
    # Imports only the module selected in the THEME SELECTION section.
    selectedThemeModule
  ];
}
