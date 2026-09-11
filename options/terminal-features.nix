# options/terminal-features.nix
#
# =====================================================================
# OPTIONS: TERMINAL THEMES
#
# Defines the common configurable theme behaviour for WezTerm and
# Neovim, and nothing else. No theme and no choice lives here.
#
# Both are set the same way, in whichever file should decide:
#
#   ven.features.terminal.wezterm.themes = {
#     list = [ "gruvbox" "nord" ];
#     default = "gruvbox";
#   };
#
#   ven.features.terminal.nvim.themes = {
#     list = { gruvbox = { plugin = "..."; settings = { ... }; }; };
#     default = "gruvbox";
#   };
#
# Shared files set them for every machine; a machine's own home file
# sets them for itself. One place decides: two files naming the same
# one is a conflict, and the machine wins it with lib.mkForce.
#
# ** WezTerm's themes are Lua files written next to its config, so a
# ** name is enough for it. A Neovim colorscheme is a plugin and the
# ** settings its setup takes, so its entries carry those.
# =====================================================================

{ config, lib, ... }:

let
  wezterm = config.ven.features.terminal.wezterm;
  nvim = config.ven.features.terminal.nvim;

  # ------------------------------------------------------------
  # ------ ONE NEOVIM COLORSCHEME ------ #
  # ------------------------------------------------------------

  nvimThemeType = lib.types.submodule (
    { name, ... }:
    {
      options = {
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

          description = ''
            The colorscheme's own settings, written as Nix rather than
            Lua. They are rendered into the plugin's opts table, so
            attribute sets nest and booleans and strings come out as
            Lua's own.
          '';
        };
      };
    }
  );

  # ------------------------------------------------------------
  # ------ WRITING A NEOVIM COLORSCHEME ------ #
  #
  # How AstroNvim wants one declared, which is the same for every
  # colorscheme: the plugin spec, astroui pointing at the colorscheme
  # name, and astrocore turning on 24-bit colour. Only the three values
  # it reads come from the theme itself.
  # ------------------------------------------------------------

  renderNvimTheme = theme: ''
    return {
      {
        "${theme.plugin}",

        priority = 1000,

        opts = ${lib.generators.toLua { multiline = true; indent = "        "; } theme.settings},
      },

      {
        "AstroNvim/astroui",

        opts = {
          colorscheme = "${theme.colorscheme}",
        },
      },

      {
        "AstroNvim/astrocore",

        opts = function(_, opts)
          opts.options = opts.options or {}
          opts.options.opt = opts.options.opt or {}

          -- ---- 24-BIT COLOUR ---- #
          -- Without this Neovim ignores the colorscheme's hex values
          -- and renders using WezTerm's 16 ANSI colours instead.
          opts.options.opt.termguicolors = true

          return opts
        end,
      },
    }
  '';

  # The colorscheme in use, or null when none is selected.
  nvimSelected = nvim.themes.list.${nvim.themes.default} or null;
in

{
  options.ven.features.terminal = {
    wezterm.themes = {
      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "gruvbox" "nord" ];
        description = ''
          Themes that can be chosen, each one a Lua file written into
          WezTerm's themes directory under the same name.
        '';
      };

      default = lib.mkOption {
        type = lib.types.str;
        default = "none";
        example = "nord";
        description = ''
          Theme to load. none leaves WezTerm's own palette alone.
        '';
      };
    };

    nvim.themes = {
      list = lib.mkOption {
        type = lib.types.attrsOf nvimThemeType;
        default = { };
        description = ''
          Colorschemes that can be chosen, each with the plugin that
          provides it and the settings its setup takes.
        '';
      };

      default = lib.mkOption {
        type = lib.types.str;
        default = "none";
        example = "nord";
        description = ''
          Colorscheme written into Neovim's plugin configuration. none
          writes no theme at all.
        '';
      };
    };
  };

  # ------------------------------------------------------------
  # ------ THE NEOVIM COLORSCHEME ------ #
  #
  # Written from the chosen theme's settings. WezTerm loads its own in
  # shared/terminal/wezterm/default.nix, straight from the Lua file.
  # ------------------------------------------------------------

  config.xdg.configFile."nvim/lua/plugins/theme.lua" =
    lib.mkIf (nvim.enable && nvimSelected != null) {
      text = renderNvimTheme nvimSelected;
    };

  # ------------------------------------------------------------
  # ------ THE CHOSEN THEME HAS TO EXIST ------ #
  #
  # A typo would otherwise reach the generated config and fail at the
  # terminal rather than at build time.
  # ------------------------------------------------------------

  config.assertions = [
    {
      assertion =
        !wezterm.enable
        || wezterm.themes.default == "none"
        || lib.elem wezterm.themes.default wezterm.themes.list;

      message = ''
        ven.features.terminal.wezterm.themes.default is "${wezterm.themes.default}",
        which is not one of: ${lib.concatStringsSep ", " wezterm.themes.list}
      '';
    }

    {
      assertion =
        !nvim.enable
        || nvim.themes.default == "none"
        || lib.hasAttr nvim.themes.default nvim.themes.list;

      message = ''
        ven.features.terminal.nvim.themes.default is "${nvim.themes.default}",
        which is not one of: ${lib.concatStringsSep ", " (lib.attrNames nvim.themes.list)}
      '';
    }
  ];
}
