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

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    micro.enable && ((isDarwin && micro.installOn.darwin) || (isLinux && micro.installOn.linux));

  # ---- THEME SELECTION ---- #
  # Change this value to select one of the themes in themes/default.nix.
  # Only the selected theme module creates a colourscheme file.
  selectedTheme = "gruvbox";

  # ---- AVAILABLE THEMES ---- #
  # The registry remains separate so this main module keeps the visible
  # selector while each theme stays in its own implementation module.
  themeModules = import ./themes;

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
    # Own Micro's colourscheme index for every Nix-managed theme.
    ./themes/micro-themes-schemas.nix

    # Imports only the module selected in the THEME SELECTION section.
    selectedThemeConfig.module
  ];
}
