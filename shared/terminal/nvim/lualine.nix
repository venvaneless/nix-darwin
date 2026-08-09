# shared/terminal/nvim/lualine.nix
#
# NEOVIM: LUALINE
# Gruvbox statusline styled to match the WezTerm tab bar.

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/lualine.lua".text = ''
      return {
        -- AstroNvim uses Heirline by default; Lualine replaces it.
        {
          "rebelot/heirline.nvim",
          enabled = false,
        },

        -- Provides the Neovim statusline.
        {
          "nvim-lualine/lualine.nvim",

          event = "BufEnter",

          dependencies = {
            "nvim-tree/nvim-web-devicons",
          },

          opts = function()
            -- Matches ~/.config/wezterm/plugins/tabline.lua.
            local colors = {
              bg0 = "#282828",
              bg1 = "#3c3836",
              bg2 = "#504945",
              fg1 = "#ebdbb2",
              gray = "#a89984",
              yellow = "#fabd2f",
              orange = "#fe8019",
              red = "#fb4934",
              aqua = "#8ec07c",
              blue = "#83a598",
            }

            local theme = {
              normal = {
                a = { bg = colors.yellow, fg = colors.bg0, gui = "bold" },
                b = { bg = colors.bg1, fg = colors.fg1 },
                c = { bg = colors.bg0, fg = colors.fg1 },
              },
              insert = {
                a = { bg = colors.aqua, fg = colors.bg0, gui = "bold" },
                b = { bg = colors.bg1, fg = colors.fg1 },
                c = { bg = colors.bg0, fg = colors.fg1 },
              },
              visual = {
                a = { bg = colors.orange, fg = colors.bg0, gui = "bold" },
                b = { bg = colors.bg1, fg = colors.fg1 },
                c = { bg = colors.bg0, fg = colors.fg1 },
              },
              replace = {
                a = { bg = colors.red, fg = colors.bg0, gui = "bold" },
                b = { bg = colors.bg1, fg = colors.fg1 },
                c = { bg = colors.bg0, fg = colors.fg1 },
              },
              command = {
                a = { bg = colors.blue, fg = colors.bg0, gui = "bold" },
                b = { bg = colors.bg1, fg = colors.fg1 },
                c = { bg = colors.bg0, fg = colors.fg1 },
              },
              inactive = {
                a = { bg = colors.bg1, fg = colors.gray },
                b = { bg = colors.bg1, fg = colors.gray },
                c = { bg = colors.bg0, fg = colors.gray },
              },
            }

            return {
              options = {
                theme = theme,
                globalstatus = true,
                component_separators = "",
                section_separators = { left = "", right = "" },

                disabled_filetypes = {
                  statusline = {
                    "aerial",
                    "alpha",
                    "dashboard",
                    "lazy",
                    "mason",
                    "neo-tree",
                    "NvimTree",
                    "toggleterm",
                  },
                },
              },

              sections = {
                lualine_a = {
                  { "mode", fmt = function(mode) return mode:sub(1, 1) end },
                },
                lualine_b = {
                  { "branch", icon = "" },
                  "diff",
                  "diagnostics",
                },
                lualine_c = {
                  {
                    "filename",
                    path = 1,
                    symbols = {
                      modified = " ●",
                      readonly = " ",
                      unnamed = "[No Name]",
                    },
                  },
                },
                lualine_x = {
                  { "lsp_status", icon = "" },
                  "filetype",
                },
                lualine_y = { "progress" },
                lualine_z = { "location" },
              },
            }
          end,
        },
      }
    '';
  };
}