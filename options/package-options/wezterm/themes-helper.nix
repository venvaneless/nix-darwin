# options/package-options/wezterm/themes-helper.nix
#
# =====================================================================
# OPTIONS: WEZTERM THEMES
#
# Declares the knob set every theme reuses, the theme selector, and
# renders only the selected theme to the Lua file its knobs name.
# Each theme's values, including its name and Lua path, live in
# shared/terminal/wezterm/themes/.
# =====================================================================

{
  config,
  lib,
  pkgs,
  platforms,
  ...
}:

let
  cfg = config.shared.terminal.wezterm;

  # ------------------------------------------------------------
  # ------ SHARED THEME KNOBS ------ #
  # ------------------------------------------------------------

  themeOptions = {
    colorScheme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "WezTerm built-in colour scheme applied before local palette overrides.";
    };

    titleButtonColor = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Integrated title button colour for this theme.";
    };

    commandPalette = {
      background = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Command palette background colour.";
      };
      foreground = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Command palette foreground colour.";
      };
    };

    windowFrame = {
      active_titlebar_bg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Active window title bar background colour.";
      };

      inactive_titlebar_bg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Inactive window title bar background colour.";
      };

      active_titlebar_fg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Active window title bar foreground colour.";
      };

      inactive_titlebar_fg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Inactive window title bar foreground colour.";
      };

      button_fg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Title bar button foreground colour.";
      };

      button_bg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Title bar button background colour.";
      };

      button_hover_fg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hovered title bar button foreground colour.";
      };

      button_hover_bg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hovered title bar button background colour.";
      };
    };

    colors = {
      foreground = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default terminal foreground colour.";
      };

      background = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default terminal background colour.";
      };

      cursor_bg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Cursor background colour.";
      };

      cursor_border = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Cursor border colour.";
      };

      cursor_fg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Text colour shown within the cursor.";
      };

      selection_bg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Selected text background colour.";
      };

      selection_fg = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Selected text foreground colour.";
      };

      scrollbar_thumb = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Scrollbar thumb colour.";
      };

      split = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Split pane divider colour.";
      };

      ansi = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "The terminal's eight standard ANSI colours.";
      };

      brights = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "The terminal's eight bright ANSI colours.";
      };

      tab_bar = {
        background = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Tab bar background colour.";
        };

        active_tab = {
          bg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Active tab background colour.";
          };

          fg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Active tab foreground colour.";
          };

          intensity = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Active tab text intensity.";
          };

          underline = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Active tab underline style.";
          };

          italic = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "Whether active tab text is italic.";
          };

          strikethrough = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "Whether active tab text is struck through.";
          };
        };

        inactive_tab = {
          bg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Inactive tab background colour.";
          };

          fg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Inactive tab foreground colour.";
          };
        };

        inactive_tab_hover = {
          bg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Hovered inactive tab background colour.";
          };

          fg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Hovered inactive tab foreground colour.";
          };

          italic = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "Whether hovered inactive tab text is italic.";
          };
        };

        new_tab = {
          bg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "New tab button background colour.";
          };

          fg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "New tab button foreground colour.";
          };
        };

        new_tab_hover = {
          bg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Hovered new tab button background colour.";
          };

          fg_color = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Hovered new tab button foreground colour.";
          };

          italic = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "Whether hovered new tab button text is italic.";
          };
        };
      };
    };
  };

  # ------------------------------------------------------------
  # ------ ONE THEME ------ #
  # Identity and output path are knobs too, so each theme file decides
  # which Lua file it is written to.
  # ------------------------------------------------------------

  themeType = lib.types.submodule (
    { name, ... }:
    {
      options = themeOptions // {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Theme name selected by themes.default. Must match the attribute name.";
        };

        title = lib.mkOption {
          type = lib.types.str;
          description = "Human-readable theme title.";
        };

        description = lib.mkOption {
          type = lib.types.str;
          description = "What this theme changes.";
        };

        relativePath = lib.mkOption {
          type = lib.types.str;
          example = ".config/wezterm/themes/gruvbox.lua";
          description = "Home-relative Lua file this theme is written to and loaded from.";
        };
      };
    }
  );

  # ------------------------------------------------------------
  # ------ SELECTOR ------ #
  # ------------------------------------------------------------

  themeSelectorOptions = {
    list = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Theme names available for selection.";
    };

    default = lib.mkOption {
      type = lib.types.str;
      default = "none";
      description = "Theme applied to WezTerm, or none to leave its palette unchanged.";
    };
  };

  # Every attribute other than the selector is a theme.
  declaredThemes = builtins.removeAttrs cfg.themes (builtins.attrNames themeSelectorOptions);

  selectedTheme = declaredThemes.${cfg.themes.default} or null;

  # ------------------------------------------------------------
  # ------ LUA RENDERING ------ #
  # ------------------------------------------------------------

  compactAttrs = attrs:
    lib.filterAttrs (_: value: value != null && value != { }) (
      lib.mapAttrs (_: value: if builtins.isAttrs value then compactAttrs value else value) attrs
    );

  renderTheme = theme:
    let
      renderFrame = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (key: value: "        config.window_frame.${key} = ${lib.generators.toLua { } value}") (compactAttrs theme.windowFrame)
      );
    in
    pkgs.writeText "${theme.name}.lua" /* lua */ ''
      local M = {}

      function M.apply(config)
          config.color_scheme = ${lib.generators.toLua { } theme.colorScheme}
          config.integrated_title_button_color = ${lib.generators.toLua { } theme.titleButtonColor}
          config.command_palette_bg_color = ${lib.generators.toLua { } theme.commandPalette.background}
          config.command_palette_fg_color = ${lib.generators.toLua { } theme.commandPalette.foreground}
          config.window_frame = config.window_frame or {}
${renderFrame}
          config.colors = ${lib.generators.toLua { multiline = true; } (compactAttrs theme.colors)}
      end

      return M
    '';
in
{
  options.shared.terminal.wezterm.themes = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.attrsOf themeType;
      options = themeSelectorOptions;
    };
    default = { };
    description = "Theme selector plus every named theme, each set in its own knob file.";
  };

  config = lib.mkIf (cfg.enable && platforms.enabledForCurrentPlatform cfg) {
    assertions = lib.mapAttrsToList (attrName: theme: {
      assertion = theme.name == attrName;
      message = ''
        shared.terminal.wezterm.themes.${attrName}.name is "${theme.name}",
        but it must match the attribute name "${attrName}".
      '';
    }) declaredThemes;

    home.file = lib.optionalAttrs (selectedTheme != null) {
      ${selectedTheme.relativePath}.source = renderTheme selectedTheme;
    };
  };
}
