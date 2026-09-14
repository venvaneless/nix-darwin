# options/cli/micro/default.nix
#
# =====================================================================
# OPTIONS: MICRO TERMINAL EDITOR
# =====================================================================
#
# Owns Micro's option shape, platform selection, configuration rendering,
# and theme implementation. shared/terminal/cli-tuis/default.nix assigns
# every user-facing Micro knob.
# =====================================================================

{ config, lib, pkgs, platforms, ... }:

let
  cfg = config.cli.micro;

  # ------------------------------------------------------------
  # ------ PLATFORM SELECTION ------ #
  # The shared CLI/TUI settings choose enablement and supported platforms.
  # This module uses the common selector instead of recreating it locally.

  enabledForCurrentPlatform = platforms.enabledForCurrentPlatform cfg;

  # ------------------------------------------------------------
  # ------ THEME REGISTRY ------ #
  # Every Nix-managed palette is installed while Micro is enabled, so the
  # colourschemes index and the files it advertises always agree.

  themeModules = import ./themes;

  selectedTheme = cfg.themes.default;
  selectedThemeConfig = themeModules.${selectedTheme} or null;
  selectedThemeName =
    if selectedThemeConfig == null then selectedTheme else selectedThemeConfig.themeName;

  enabledThemes = lib.mapAttrs (_: _: { enable = true; }) themeModules;

  # ------------------------------------------------------------
  # ------ RENDERED SETTINGS ------ #
  # The selected theme determines Micro's colorscheme; all other editor
  # preferences arrive as knobs from the shared CLI/TUI settings file.

  settingsJson = builtins.toJSON (
    cfg.settings
    // {
      colorscheme = selectedThemeName;
    }
  );

  bindingsJson = builtins.toJSON cfg.bindings;
in
{
  options.cli.micro = {
    enable = lib.mkEnableOption "Micro terminal text editor";

    installOn = {
      darwin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure Micro on macOS.";
      };

      linux = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure Micro on Linux.";
      };
    };

    enabledForCurrentPlatform = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether Micro is enabled for the Home Manager host currently being built.";
    };

    trueColor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Request true-colour rendering from Micro.";
    };

    themes.default = lib.mkOption {
      type = lib.types.str;
      default = "gruvbox";
      description = "Name of the Nix-managed Micro theme selected in settings.json.";
    };

    settings = {
      clipboard = lib.mkOption {
        type = lib.types.str;
        default = "external";
        description = "Clipboard provider Micro uses.";
      };

      savecursor = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Restore the cursor position when reopening a file.";
      };

      saveundo = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Persist undo history between Micro sessions.";
      };

      scrollbar = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show Micro's scrollbar.";
      };

      softwrap = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Wrap long lines instead of scrolling horizontally.";
      };

      tabsize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4;
        description = "Number of columns in one tab stop.";
      };

      tabstospaces = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Insert spaces when the Tab key is pressed.";
      };
    };

    bindings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Micro keybinding names mapped to their commands.";
    };
  };

  config = lib.mkMerge [
    {
      cli.micro.enabledForCurrentPlatform = enabledForCurrentPlatform;
    }
    (lib.mkIf enabledForCurrentPlatform {
      # Install Micro as a user-scoped cross-platform CLI tool.
      home.packages = [ pkgs.micro ];

      # Custom themes need full terminal colour support on every platform.
      home.sessionVariables = lib.optionalAttrs cfg.trueColor {
        MICRO_TRUECOLOR = "1";
      };

      # Theme modules use internal switches; all are enabled together so
      # changing themes never leaves colorschemes.json pointing at no file.
      cli.micro.themes = enabledThemes;

      xdg.configFile = {
        # Core editor settings, including the selected colourscheme name.
        "micro/settings.json".text = settingsJson;

        # Shared knobs preserve the existing comment, clipboard, and selection bindings.
        "micro/bindings.json".text = bindingsJson;
      };
    })
  ];

  assertions = [
    {
      assertion = !enabledForCurrentPlatform || selectedThemeConfig != null;
      message = ''
        cli.micro.themes.default is "${selectedTheme}",
        which is not one of: ${lib.concatStringsSep ", " (lib.attrNames themeModules)}
      '';
    }
  ];

  imports = [
    # Own Micro's colourscheme index for every Nix-managed theme.
    ./themes/micro-themes-schemas.nix
  ] ++ map (theme: theme.module) (lib.attrValues themeModules);
}
