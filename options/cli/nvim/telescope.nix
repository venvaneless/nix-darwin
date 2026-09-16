# options/cli/nvim/telescope.nix
#
# =====================================================================
# OPTIONS: NEOVIM TELESCOPE
#
# Declares the Telescope knobs and writes their Lua file.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  telescope = cfg.telescope;
in
{
  options.home.shared.terminal.nvim.telescope = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure the Telescope fuzzy finder.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "nvim-telescope/telescope.nvim";
      description = "Plugin providing the fuzzy finder.";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "*";
      description = "Plugin version Lazy installs.";
    };

    dependencies = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "nvim-lua/plenary.nvim" ];
      description = "Plugins Telescope needs.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/telescope.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    layoutStrategy = lib.mkOption {
      type = lib.types.str;
      default = "horizontal";
      description = "Telescope window layout.";
    };

    sortingStrategy = lib.mkOption {
      type = lib.types.str;
      default = "ascending";
      description = "Order in which results are listed.";
    };

    promptPosition = lib.mkOption {
      type = lib.types.str;
      default = "top";
      description = "Where the prompt sits in the Telescope window.";
    };

    previewWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.55;
      description = "Share of the window given to the preview pane.";
    };

    width = lib.mkOption {
      type = lib.types.float;
      default = 0.9;
      description = "Share of the editor the Telescope window covers.";
    };

    height = lib.mkOption {
      type = lib.types.float;
      default = 0.85;
      description = "Share of the editor height the Telescope window covers.";
    };
  };

  config = lib.mkIf (cfg.enable && telescope.enable) {
    xdg.configFile.${telescope.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ telescope.plugin ];

        version = telescope.version;
        dependencies = telescope.dependencies;

        opts.defaults = {
          layout_strategy = telescope.layoutStrategy;
          sorting_strategy = telescope.sortingStrategy;

          layout_config = {
            prompt_position = telescope.promptPosition;
            preview_width = telescope.previewWidth;
            width = telescope.width;
            height = telescope.height;
          };
        };
      }
    ];
  };
}
