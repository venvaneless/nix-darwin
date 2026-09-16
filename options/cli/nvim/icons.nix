# options/cli/nvim/icons.nix
#
# =====================================================================
# OPTIONS: NEOVIM ICONS
#
# Declares the icon knobs and writes their Lua file.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  icons = cfg.icons;

  iconOptions =
    lib.optionalAttrs (icons.overrides != { }) { override = icons.overrides; }
    // lib.optionalAttrs (icons.byFiletype != { }) { override_by_filetype = icons.byFiletype; }
    // lib.optionalAttrs (icons.byExtension != { }) { override_by_extension = icons.byExtension; }
    // lib.optionalAttrs icons.colourIcons { color_icons = true; }
    // lib.optionalAttrs icons.fallbackIcon { default = true; };
in
{
  options.home.shared.terminal.nvim.icons = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Load the file and language icons used by the Neovim UI.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "nvim-tree/nvim-web-devicons";
      description = "Plugin providing the icons.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/icons.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    lazy = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Load the icon plugin only when another plugin asks for it.";
    };

    colourIcons = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Colour each icon by file type.";
    };

    fallbackIcon = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show a fallback icon for unknown file types.";
    };

    overrides = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      example = lib.literalExpression ''{ nix = { icon = "❄"; name = "Nix"; }; }'';
      description = "Icon, colour, and name for a given file type.";
    };

    byFiletype = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Icon overrides matched on Neovim's file type.";
    };

    byExtension = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Icon overrides matched on the file extension.";
    };
  };

  config = lib.mkIf (cfg.enable && icons.enable) {
    xdg.configFile.${icons.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ icons.plugin ];

        lazy = icons.lazy;
        opts = iconOptions;
      }
    ];
  };
}
