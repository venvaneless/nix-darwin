# options/cli/nvim/dropbar.nix
#
# =====================================================================
# OPTIONS: NEOVIM DROPBAR
#
# Declares the breadcrumb knobs and writes their Lua file.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  dropbar = cfg.dropbar;

  # A highlight names palette entries; a literal colour is used as written.
  colour = name: dropbar.palette.${name} or name;

  highlight = entry:
    { fg = colour entry.fg; bg = colour entry.bg; }
    // lib.optionalAttrs entry.bold { bold = true; };

  # Each kind group produces the text highlight and its icon highlight.
  kindHighlights = lib.concatMapAttrs (
    _: group:
    lib.listToAttrs (
      lib.concatMap (kind: [
        (lib.nameValuePair "DropBarKind${kind}" { inherit (group) fg bg bold; })
        (lib.nameValuePair "DropBarIconKind${kind}" { inherit (group) fg bg; bold = false; })
      ]) group.kinds
    )
  ) dropbar.kindGroups;

  allHighlights = lib.mapAttrs (_: highlight) (dropbar.highlights // kindHighlights);

  renderHighlight = group: value:
    "vim.api.nvim_set_hl(0, \"${group}\", ${lua.render "    " value})";

  highlightLines = lib.concatStringsSep "\n    " (lib.mapAttrsToList renderHighlight allHighlights);

  renderKeymap = keymap:
    ''vim.keymap.set("n", "${keymap.key}", dropbar_api.${keymap.action}, { desc = "${keymap.description}" })'';

  keymapLines = lib.concatStringsSep "\n    " (map renderKeymap (lib.attrValues dropbar.keymaps));

  highlightType = lib.types.submodule {
    options = {
      fg = lib.mkOption {
        type = lib.types.str;
        description = "Palette name or hex colour for the text.";
      };

      bg = lib.mkOption {
        type = lib.types.str;
        description = "Palette name or hex colour for the background.";
      };

      bold = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Draw the text in bold.";
      };
    };
  };
in
{
  options.home.shared.terminal.nvim.dropbar = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show clickable breadcrumb navigation.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "Bekaboo/dropbar.nvim";
      description = "Plugin providing the breadcrumbs.";
    };

    dependencies = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Plugins the breadcrumbs need.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/dropbar.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    icons.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show an icon beside each breadcrumb.";
    };

    separator = lib.mkOption {
      type = lib.types.str;
      default = "  ";
      description = "Text drawn between breadcrumbs.";
    };

    extends = lib.mkOption {
      type = lib.types.str;
      default = "…";
      description = "Text shown where the breadcrumb trail is cut short.";
    };

    padding = {
      left = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Blank columns before the first breadcrumb.";
      };

      right = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Blank columns after the last breadcrumb.";
      };
    };

    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ bg0 = "#282828"; yellow = "#fabd2f"; }'';
      description = "Named colours the breadcrumb highlights use.";
    };

    highlights = lib.mkOption {
      type = lib.types.attrsOf highlightType;
      default = { };
      example = lib.literalExpression ''{ WinBar = { fg = "fg1"; bg = "bg0"; }; }'';
      description = "Highlight groups set directly by name.";
    };

    kindGroups = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            kinds = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Symbol kinds that share these colours, such as Function or Class.";
            };

            fg = lib.mkOption {
              type = lib.types.str;
              description = "Palette name or hex colour for the text.";
            };

            bg = lib.mkOption {
              type = lib.types.str;
              description = "Palette name or hex colour for the background.";
            };

            bold = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Draw the kind's name in bold. Its icon is never bold.";
            };
          };
        }
      );
      default = { };
      description = "Symbol kinds grouped by the colours they share.";
    };

    keymaps = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            key = lib.mkOption {
              type = lib.types.str;
              description = "Key sequence this mapping binds.";
            };

            action = lib.mkOption {
              type = lib.types.str;
              example = "pick";
              description = "Function on dropbar.api the key calls.";
            };

            description = lib.mkOption {
              type = lib.types.str;
              description = "What the mapping does.";
            };
          };
        }
      );
      default = { };
      description = "Breadcrumb mappings.";
    };
  };

  config = lib.mkIf (cfg.enable && dropbar.enable) {
    xdg.configFile.${dropbar.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ dropbar.plugin ];

        dependencies = dropbar.dependencies;

        opts = {
          icons = {
            enable = dropbar.icons.enable;

            ui.bar = {
              separator = dropbar.separator;
              extends = dropbar.extends;
            };
          };

          bar.padding = {
            inherit (dropbar.padding) left right;
          };
        };

        # The highlights are re-applied after a colorscheme change.
        config = lua.raw ''
          function(_, opts)
            local function apply_highlights()
              ${highlightLines}
            end

            apply_highlights()
            require("dropbar").setup(opts)

            vim.api.nvim_create_autocmd("ColorScheme", {
              callback = apply_highlights,
            })

            local dropbar_api = require("dropbar.api")

            ${keymapLines}
          end
        '';
      }
    ];
  };
}
