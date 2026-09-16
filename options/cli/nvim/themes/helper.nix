# options/cli/nvim/themes/helper.nix
#
# =====================================================================
# OPTIONS: NEOVIM THEMES
#
# Shared theme knobs every colorscheme reuses, the theme selector, and
# the rendering of the selected theme into the file its knobs name.
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.home.shared.terminal.nvim;

  # ------------------------------------------------------------
  # ------ ONE THEME ------ #
  # ------------------------------------------------------------

  themeType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Theme name selected by theme. Must match the attribute name.";
        };

        plugin = lib.mkOption {
          type = lib.types.str;
          example = "ellisonleao/gruvbox.nvim";
          description = "Plugin providing the ${name} colorscheme.";
        };

        colorscheme = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Name Neovim loads this colorscheme by.";
        };

        priority = lib.mkOption {
          type = lib.types.int;
          default = 1000;
          description = "Lazy load priority; a colorscheme must load before other plugins.";
        };

        relativePath = lib.mkOption {
          type = lib.types.str;
          default = "nvim/lua/plugins/theme.lua";
          example = "nvim/lua/plugins/theme.lua";
          description = "Config-relative Lua file this theme is written to.";
        };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          example = lib.literalExpression ''
            {
              contrast = "";
              bold = true;
              italic.comments = true;
            }
          '';
          description = "The colorscheme plugin's own options.";
        };

        termguicolors = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Use 24-bit colour, without which Neovim ignores the palette's hex values.";
        };

        highlights = lib.mkOption {
          type = lib.types.attrsOf lib.types.attrs;
          default = { };
          example = lib.literalExpression ''{ Comment = { italic = true; }; }'';
          description = "Highlight groups this theme overrides, applied through astroui.";
        };

        statusline = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "astroui status settings this theme sets, such as separators and colours.";
        };

        icons = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "astroui icon overrides this theme sets.";
        };
      };
    }
  );

  selectedTheme = cfg.themes.${cfg.theme} or null;

  # ------------------------------------------------------------
  # ------ THEME RENDERING ------ #
  # ------------------------------------------------------------

  lua = value: lib.generators.toLua { multiline = true; indent = "        "; } value;

  astrouiOptions = theme:
    lib.optionalAttrs (theme.highlights != { }) { highlights.init = theme.highlights; }
    // lib.optionalAttrs (theme.icons != { }) { icons = theme.icons; }
    // lib.optionalAttrs (theme.statusline != { }) { status = theme.statusline; }
    // { colorscheme = theme.colorscheme; };

  renderTheme = theme: ''
    return {
      {
        "${theme.plugin}",

        priority = ${toString theme.priority},

        opts = ${lua theme.settings},
      },

      {
        "AstroNvim/astroui",

        opts = ${lua (astrouiOptions theme)},
      },

      {
        "AstroNvim/astrocore",

        opts = function(_, opts)
          opts.options = opts.options or {}
          opts.options.opt = opts.options.opt or {}

          opts.options.opt.termguicolors = ${if theme.termguicolors then "true" else "false"}

          return opts
        end,
      },
    }
  '';
in
{
  options.home.shared.terminal.nvim = {
    theme = lib.mkOption {
      type = lib.types.str;
      default = "none";
      example = "nord";
      description = "Colorscheme rendered into Neovim, or none to leave it unchanged.";
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf themeType;
      default = { };
      description = "Every named Neovim colorscheme, each set in its own knob file.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      [
        {
          assertion = cfg.theme == "none" || selectedTheme != null;
          message = ''
            home.shared.terminal.nvim.theme is "${cfg.theme}",
            which is not one of: none, ${lib.concatStringsSep ", " (lib.attrNames cfg.themes)}
          '';
        }
      ]
      ++ lib.mapAttrsToList (attrName: theme: {
        assertion = theme.name == attrName;
        message = ''
          home.shared.terminal.nvim.themes.${attrName}.name is "${theme.name}",
          but it must match the attribute name "${attrName}".
        '';
      }) cfg.themes;

    xdg.configFile = lib.optionalAttrs (selectedTheme != null) {
      ${selectedTheme.relativePath}.text = renderTheme selectedTheme;
    };
  };
}
