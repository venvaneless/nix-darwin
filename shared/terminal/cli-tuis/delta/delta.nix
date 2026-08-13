# shared/terminal/cli-tuis/delta/delta.nix
#
# =====================================================================
# DELTA
#
# Syntax-highlighting pager for git and diff output
#
# Installation and behaviour are managed through Home Manager. Colours
# live in their own theme files as named delta features. Select one
# directly below; delta imports and enables only that one module.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.delta;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Delta's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.delta.enable directly.
  delta = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    delta.enable && ((isDarwin && delta.installOn.darwin) || (isLinux && delta.installOn.linux));

  # ---- THEME SELECTION ---- #
  # Change this value to select a different saved delta theme. The
  # Default selection leaves delta on its own built-in colours.
  selectedTheme = "gruvbox";

  # ---- AVAILABLE THEMES ---- #
  # Each palette remains separate, but only selectedTheme is imported.
  themeModules = {
    default = {
      module = null;
      option = null;
    };
    gruvbox = {
      module = ./themes/gruvbox.nix;
      option = "gruvbox";
    };
  };

  selectedThemeConfig =
    if lib.hasAttr selectedTheme themeModules then
      themeModules.${selectedTheme}
    else
      throw ''
        delta: unknown selectedTheme "${selectedTheme}".
        Choose one of: ${lib.concatStringsSep ", " (lib.attrNames themeModules)}
      '';
in
{
  options.ven.features.terminal.cliTuis.delta.enable =
    lib.mkEnableOption "Delta syntax-highlighting pager";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.delta.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      programs.delta = {
        # Install delta and enable its Git integration
        enable = true;
        enableGitIntegration = true;

        # ---- OPTIONS ---- #
        # Layout and navigation only. Every colour, including the syntax
        # theme, belongs to the selected theme module so that the two
        # never disagree: options set here always win over a feature.
        #
        # `dark` and `light` belong to the theme too. A value here would
        # override the feature and force a future light theme into dark
        # mode, and delta only counts a feature as a theme when the
        # feature itself declares one of the two.
        options = {

          # Set delta's navigation option
          navigate = true;

          # Enable line numbers
          line-numbers = true;

          # Enable side-by-side view
          side-by-side = true;
        };
      };
    })
    (lib.mkIf (cfg.enable && selectedThemeConfig.option != null) {
      # Only the selected theme module is imported and enabled.
      ven.features.terminal.cliTuis.delta.themes.${selectedThemeConfig.option}.enable = true;
    })
  ];

  imports = lib.optional (selectedThemeConfig.module != null) selectedThemeConfig.module;
}
