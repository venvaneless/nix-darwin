# options/cli/nvim/notify.nix
#
# =====================================================================
# OPTIONS: NEOVIM NOTIFICATIONS
#
# Declares the notifier knobs and writes their Lua file. AstroNvim
# already routes vim.notify through snacks, so nvim-notify is not used.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  notify = cfg.notify;

  colour = name: notify.palette.${name} or name;

  levelColours = lib.mapAttrs (_: name: colour name) notify.levelColours;

  # snacks derives its per-level groups from these names.
  highlightLua = ''
    local levels = ${lua.render "  " levelColours}

    local function apply()
      for level, colour in pairs(levels) do
        vim.api.nvim_set_hl(0, "SnacksNotifier" .. level, {
          fg = colour,
          bg = "${colour notify.backgroundColour}",
        })

        for _, part in ipairs(${lua.render "      " notify.accentParts}) do
          vim.api.nvim_set_hl(0, "SnacksNotifier" .. part .. level, {
            fg = colour,
            bg = "${colour notify.backgroundColour}",
            bold = part == "${notify.boldPart}",
          })
        end
      end

      vim.api.nvim_set_hl(0, "SnacksNotifierHistory", {
        fg = "${colour notify.historyForeground}",
        bg = "${colour notify.backgroundColour}",
      })
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
      desc = "Colours for snacks notifications",
      callback = apply,
    })

    vim.schedule(apply)
  '';

  mappingLua = lib.concatStringsSep "\n\n    " (
    lib.mapAttrsToList (_: mapping: ''
      opts.mappings.n["${mapping.key}"] = {
          function()
            require("snacks").notifier.${mapping.action}()
          end,

          desc = "${mapping.description}",
        }'') notify.keymaps
  );
in
{
  options.home.shared.terminal.nvim.notify = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Style the snacks notifier used for vim.notify.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "folke/snacks.nvim";
      description = "Plugin providing the notifier.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/notify.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    timeout = lib.mkOption {
      type = lib.types.int;
      default = 3000;
      description = "Milliseconds a notification stays on screen. 0 keeps it until dismissed.";
    };

    refresh = lib.mkOption {
      type = lib.types.int;
      default = 50;
      description = "Shortest time in milliseconds between redraws.";
    };

    width = {
      min = lib.mkOption {
        type = lib.types.int;
        default = 40;
        description = "Narrowest notification, in cells.";
      };

      max = lib.mkOption {
        type = lib.types.float;
        default = 0.4;
        description = "Widest notification, as a share of the editor.";
      };
    };

    height = {
      min = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Shortest notification, in rows.";
      };

      max = lib.mkOption {
        type = lib.types.float;
        default = 0.6;
        description = "Tallest notification, as a share of the editor.";
      };
    };

    margin = {
      top = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Rows kept clear above the stack.";
      };

      right = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Columns kept clear of the right-hand edge.";
      };

      bottom = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Rows kept clear below the stack.";
      };
    };

    padding = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Pad the text inside each notification.";
    };

    gap = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Rows between stacked notifications.";
    };

    style = lib.mkOption {
      type = lib.types.enum [ "compact" "fancy" "minimal" ];
      default = "compact";
      description = "compact borders the icon and title, fancy is the nvim-notify look, minimal drops the border.";
    };

    topDown = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Stack downward from the top right.";
    };

    sort = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "level" "added" ];
      description = "Order notifications are stacked in.";
    };

    level = lib.mkOption {
      type = lib.types.str;
      default = "TRACE";
      description = "Lowest level recorded in history, as a vim.log.levels name.";
    };

    dateFormat = lib.mkOption {
      type = lib.types.str;
      default = "%R";
      description = "Timestamp shown on each notification.";
    };

    moreFormat = lib.mkOption {
      type = lib.types.str;
      default = " ↓ %d lines ";
      description = "Text shown where a notification is cut short.";
    };

    keepWhileTyping = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hold notifications open while the command line is active.";
    };

    icons = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ error = " "; }'';
      description = "Icon shown for each level.";
    };

    border = lib.mkOption {
      type = lib.types.str;
      default = "rounded";
      description = "Border drawn around a notification.";
    };

    blend = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Window transparency. 0 keeps the colours solid.";
    };

    wrap = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Wrap long lines inside a notification.";
    };

    historyTitle = lib.mkOption {
      type = lib.types.str;
      default = " Notifications ";
      description = "Title of the notification history window.";
    };

    historyTitlePosition = lib.mkOption {
      type = lib.types.str;
      default = "center";
      description = "Where the history window's title sits.";
    };

    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Named colours the notification highlights use.";
    };

    levelColours = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ Error = "red"; Warn = "yellow"; }'';
      description = "Palette name or hex colour for each level.";
    };

    backgroundColour = lib.mkOption {
      type = lib.types.str;
      default = "bg1";
      description = "Palette name or hex colour behind every notification.";
    };

    historyForeground = lib.mkOption {
      type = lib.types.str;
      default = "fg1";
      description = "Palette name or hex colour for the history text.";
    };

    accentParts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "Icon" "Title" "Border" "Footer" ];
      description = "Parts of a notification that carry the level's colour.";
    };

    boldPart = lib.mkOption {
      type = lib.types.str;
      default = "Title";
      description = "The one part drawn in bold.";
    };

    themePlugin = lib.mkOption {
      type = lib.types.str;
      default = "ellisonleao/gruvbox.nvim";
      description = "Colorscheme plugin the highlights are attached to.";
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
              example = "show_history";
              description = "Function on snacks.notifier the key calls.";
            };

            description = lib.mkOption {
              type = lib.types.str;
              description = "What the mapping does.";
            };
          };
        }
      );
      default = { };
      description = "Notification mappings.";
    };
  };

  config = lib.mkIf (cfg.enable && notify.enable) {
    xdg.configFile.${notify.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ notify.plugin ];

        opts = {
          notifier = {
            enabled = true;

            inherit (notify) timeout refresh padding gap style sort;

            width = { inherit (notify.width) min max; };
            height = { inherit (notify.height) min max; };
            margin = { inherit (notify.margin) top right bottom; };

            top_down = notify.topDown;
            level = lua.raw "vim.log.levels.${notify.level}";
            date_format = notify.dateFormat;
            more_format = notify.moreFormat;

            keep =
              if notify.keepWhileTyping then
                lua.raw ''
                  function()
                    return vim.fn.getcmdpos() > 0
                  end
                ''
              else
                null;

            icons = notify.icons;
          };

          styles = {
            notification = {
              border = notify.border;

              wo = {
                winblend = notify.blend;
                wrap = notify.wrap;
              };
            };

            notification_history = {
              border = notify.border;
              title = notify.historyTitle;
              title_pos = notify.historyTitlePosition;
            };
          };
        };
      }

      {
        __positional = [ "AstroNvim/astrocore" ];

        opts = lua.raw ''
          function(_, opts)
            opts.mappings = opts.mappings or {}
            opts.mappings.n = opts.mappings.n or {}

            ${mappingLua}

            return opts
          end
        '';
      }

      {
        __positional = [ notify.themePlugin ];

        opts = lua.raw ''
          function(_, opts)
            ${highlightLua}

            return opts
          end
        '';
      }
    ];
  };
}
