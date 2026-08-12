# shared/terminal/cli-tuis/micro/micro.nix
#
# =====================================================================
# MICRO
#
# Modern terminal text editor with declarative settings, keybindings,
# and a selected colour theme.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.micro;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Micro's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.micro.enable directly.
  micro = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  enabledForCurrentSystem =
    micro.enable && ((isDarwin && micro.installOn.darwin) || (isLinux && micro.installOn.linux));

  # ---- THEME SELECTION ---- #
  # Change this value to select the saved Catppuccin Mocha or Gruvbox
  # palette. Only the selected theme module creates a colourscheme file.
  selectedTheme = "gruvbox";

  # ---- AVAILABLE THEMES ---- #
  themeModules = {
    catppuccin = {
      module = ./themes/catppuccin-mocha.nix;
      themeName = "catppuccin-mocha";
    };
    gruvbox = {
      module = ./themes/gruvbox.nix;
      themeName = "gruvbox";
    };
  };

  selectedThemeConfig =
    if lib.hasAttr selectedTheme themeModules then
      themeModules.${selectedTheme}
    else
      throw ''
        micro: unknown selectedTheme "${selectedTheme}".
        Choose one of: ${lib.concatStringsSep ", " (lib.attrNames themeModules)}
      '';

  # ---- PRESERVED SETTINGS ---- #
  # These options and keybindings were imported from micro.zip.
  settingsJson = builtins.toJSON {
    colorscheme = selectedThemeConfig.themeName;
    clipboard = "external";
    savecursor = true;
    saveundo = true;
    scrollbar = true;
    softwrap = false;
    tabsize = 4;
    tabstospaces = true;
  };
in
{
  options.ven.features.terminal.cliTuis.micro.enable = lib.mkEnableOption "Micro terminal text editor";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.micro.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      # Install Micro as a user-scoped cross-platform CLI tool.
      home.packages = [ pkgs.micro ];

      # Custom themes need full terminal colour support on every platform.
      home.sessionVariables.MICRO_TRUECOLOR = "1";

      # Enable only the theme selected above.
      ven.features.terminal.cliTuis.micro.themes.${selectedTheme}.enable = true;

      xdg.configFile = {
        # Core editor settings, including the selected colourscheme name.
        "micro/settings.json".text = settingsJson;

        # Preserve the archive's comment, clipboard, and selection bindings.
        "micro/bindings.json".text = ''
          {
            "Alt-/": "lua:comment.comment",
            "CtrlUnderscore": "lua:comment.comment",
            "CtrlC": "Copy",
            "CtrlW": "Paste",
            "CtrlX": "Cut",
            "CtrlA": "SelectAll"
          }
        '';
      };
    })
  ];

  imports = [
    # Imports only the module selected in the THEME SELECTION section.
    selectedThemeConfig.module
  ];
}
