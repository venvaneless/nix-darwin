# shared/terminal/nvim/keyboard.nix

# =====================================================================
# NEOVIM: KEYBOARD
#
# Shared AstroNvim keyboard mappings
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/keyboard.lua".text = ''
      return {
        {
          "AstroNvim/astrocore",

          opts = {
            mappings = {

              -- NORMAL MODE
              n = {

                -- Save current file
                ["<C-s>"] = {
                  "<cmd>w<cr>",
                  desc = "Save file",
                },

                -- Close current buffer
                ["<Leader>q"] = {
                  "<cmd>bd<cr>",
                  desc = "Close buffer",
                },

                -- Toggle file explorer
                ["<Leader>e"] = {
                  "<cmd>Neotree toggle<cr>",
                  desc = "Toggle file explorer",
                },

                -- Find project files
                ["<Leader>ff"] = {
                  "<cmd>Telescope find_files<cr>",
                  desc = "Find files",
                },

                -- Search project text
                ["<Leader>fg"] = {
                  "<cmd>Telescope live_grep<cr>",
                  desc = "Find text",
                },

                -- Search open buffers
                ["<Leader>fb"] = {
                  "<cmd>Telescope buffers<cr>",
                  desc = "Find buffers",
                },

                -- Search Neovim help
                ["<Leader>fh"] = {
                  "<cmd>Telescope help_tags<cr>",
                  desc = "Find help",
                },

                -- Next buffer
                ["]b"] = {
                  function()
                    require("astrocore.buffer").nav(vim.v.count1)
                  end,

                  desc = "Next buffer",
                },

                -- Previous buffer
                ["[b"] = {
                  function()
                    require("astrocore.buffer").nav(-vim.v.count1)
                  end,

                  desc = "Previous buffer",
                },
              },

              -- INSERT MODE
              i = {

                -- Escape insert mode
                ["jk"] = {
                  "<Esc>",
                  desc = "Exit insert mode",
                },
              },
            },
          },
        },
      }
    '';
  };
}
