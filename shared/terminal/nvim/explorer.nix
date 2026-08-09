# shared/terminal/nvim/explorer.nix

# =====================================================================
# NEOVIM: FILE EXPLORER
#
# Persistent Neo-tree project sidebar
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/explorer.lua".text = ''
      return {
        {
          "nvim-neo-tree/neo-tree.nvim",

          opts = {
            filesystem = {
              follow_current_file = {
                enabled = true,
              },

              filtered_items = {
                visible = true,

                hide_dotfiles = false,
                hide_gitignored = false,
              },
            },

            window = {
              position = "left",
              width = 35,
            },
          },

          init = function()
            vim.api.nvim_create_autocmd("VimEnter", {
              callback = function()
                vim.schedule(function()
                  vim.cmd("Neotree show")
                end)
              end,
            })
          end,
        },
      }
    '';
  };
}
