# shared/terminal/nvim/dropbar.nix

# =====================================================================
# NEOVIM: DROPBAR
#
# Clickable breadcrumb navigation using the shared Gruvbox palette
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/dropbar.lua".text = ''
      return {
        {
          "Bekaboo/dropbar.nvim",

          dependencies = {
            "nvim-tree/nvim-web-devicons",
          },

          opts = {
            icons = {
              enable = true,

              ui = {
                bar = {
                  separator = "  ",
                  extends = "…",
                },
              },
            },

            bar = {
              padding = {
                left = 1,
                right = 1,
              },
            },
          },

          config = function(_, opts)
            local colors = {
              bg0 = "#282828",
              bg1 = "#3c3836",
              fg1 = "#ebdbb2",
              gray = "#a89984",
              yellow = "#fabd2f",
              orange = "#fe8019",
              aqua = "#83a598",
              green = "#b8bb26",
            }

            local function apply_highlights()
              vim.api.nvim_set_hl(0, "WinBar", { fg = colors.fg1, bg = colors.bg0 })
              vim.api.nvim_set_hl(0, "WinBarNC", { fg = colors.gray, bg = colors.bg0 })

              vim.api.nvim_set_hl(0, "DropBarIconUISeparator", { fg = colors.yellow, bg = colors.bg0 })
              vim.api.nvim_set_hl(0, "DropBarIconUISeparatorMenu", { fg = colors.orange, bg = colors.bg0 })

              vim.api.nvim_set_hl(0, "DropBarIconKindDefault", { fg = colors.aqua, bg = colors.bg0 })
              vim.api.nvim_set_hl(0, "DropBarIconKindFolder", { fg = colors.yellow, bg = colors.bg0 })
              vim.api.nvim_set_hl(0, "DropBarIconKindFile", { fg = colors.aqua, bg = colors.bg0 })

              vim.api.nvim_set_hl(0, "DropBarKindDefault", { fg = colors.fg1, bg = colors.bg0 })
              vim.api.nvim_set_hl(0, "DropBarKindFolder", { fg = colors.yellow, bg = colors.bg0, bold = true })
              vim.api.nvim_set_hl(0, "DropBarKindFile", { fg = colors.aqua, bg = colors.bg0, bold = true })

              for _, kind in ipairs({ "Function", "Method", "Constructor", "Class", "Interface" }) do
                vim.api.nvim_set_hl(0, "DropBarKind" .. kind, { fg = colors.green, bg = colors.bg0, bold = true })
                vim.api.nvim_set_hl(0, "DropBarIconKind" .. kind, { fg = colors.green, bg = colors.bg0 })
              end

              for _, kind in ipairs({ "Variable", "Field", "Property", "Constant" }) do
                vim.api.nvim_set_hl(0, "DropBarKind" .. kind, { fg = colors.aqua, bg = colors.bg0 })
                vim.api.nvim_set_hl(0, "DropBarIconKind" .. kind, { fg = colors.aqua, bg = colors.bg0 })
              end

              for _, kind in ipairs({ "Module", "Namespace", "Package" }) do
                vim.api.nvim_set_hl(0, "DropBarKind" .. kind, { fg = colors.orange, bg = colors.bg0, bold = true })
                vim.api.nvim_set_hl(0, "DropBarIconKind" .. kind, { fg = colors.orange, bg = colors.bg0 })
              end

              vim.api.nvim_set_hl(0, "DropBarCurrentContext", { fg = colors.bg0, bg = colors.yellow, bold = true })
              vim.api.nvim_set_hl(0, "DropBarCurrentContextIcon", { fg = colors.bg0, bg = colors.yellow, bold = true })
              vim.api.nvim_set_hl(0, "DropBarCurrentContextName", { fg = colors.bg0, bg = colors.yellow, bold = true })
              vim.api.nvim_set_hl(0, "DropBarHover", { fg = colors.bg0, bg = colors.aqua })

              vim.api.nvim_set_hl(0, "DropBarMenuNormalFloat", { fg = colors.fg1, bg = colors.bg1 })
              vim.api.nvim_set_hl(0, "DropBarMenuFloatBorder", { fg = colors.yellow, bg = colors.bg1 })
              vim.api.nvim_set_hl(0, "DropBarMenuCurrentContext", { fg = colors.bg0, bg = colors.yellow, bold = true })
              vim.api.nvim_set_hl(0, "DropBarMenuHoverEntry", { fg = colors.bg0, bg = colors.aqua })
            end

            apply_highlights()
            require("dropbar").setup(opts)

            vim.api.nvim_create_autocmd("ColorScheme", {
              callback = apply_highlights,
            })

            local dropbar_api = require("dropbar.api")

            vim.keymap.set("n", "<Leader>;", dropbar_api.pick, {
              desc = "Dropbar: Pick breadcrumb",
            })

            vim.keymap.set("n", "[;", dropbar_api.goto_context_start, {
              desc = "Dropbar: Go to context start",
            })

            vim.keymap.set("n", "];", dropbar_api.select_next_context, {
              desc = "Dropbar: Select next context",
            })
          end,
        },
      }
    '';
  };
}
