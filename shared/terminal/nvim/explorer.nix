# shared/terminal/nvim/explorer.nix

# =====================================================================
# NEOVIM: FILE EXPLORER
#
# Persistent Neo-tree project sidebar with Zed-style Git colouring
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/explorer.lua".text = ''
      return {
        {
          "nvim-neo-tree/neo-tree.nvim",

          opts = function(_, opts)
            -- ---- GIT STATUS ---- #
            opts.enable_git_status = true
            opts.git_status_async = true

            opts.filesystem = vim.tbl_deep_extend("force", opts.filesystem or {}, {
              follow_current_file = {
                enabled = true,
              },

              filtered_items = {
                visible = true,

                hide_dotfiles = false,
                hide_gitignored = false,
              },
            })

            opts.window = vim.tbl_deep_extend("force", opts.window or {}, {
              position = "left",
              width = 35,
            })

            opts.default_component_configs = vim.tbl_deep_extend(
              "force",
              opts.default_component_configs or {},
              {
                -- Colour the file name itself by Git state, not just the symbol.
                name = {
                  use_git_status_colors = true,
                },

                -- Neo-tree ships this column but hides it below an 88 column
                -- window. The sidebar is 35 wide, so lower the requirement and
                -- use relative timestamps to keep it short.
                last_modified = {
                  enabled = true,
                  width = 11,
                  required_width = 30,
                  format = require("neo-tree.utils").relative_date,
                },
              }
            )

            return opts
          end,

          init = function()
            -- ---- GIT HIGHLIGHT COLOURS ---- #
            -- Gruvbox palette, matching the statusline:
            -- green = new, yellow = modified, red = deleted,
            -- default foreground = unchanged or committed.
            local function apply_git_highlights()
              local groups = {
                NeoTreeGitAdded = { fg = "#b8bb26" },
                NeoTreeGitUntracked = { fg = "#b8bb26" },
                NeoTreeGitStaged = { fg = "#8ec07c" },
                NeoTreeGitModified = { fg = "#fabd2f" },
                NeoTreeGitUnstaged = { fg = "#fabd2f" },
                NeoTreeGitRenamed = { fg = "#83a598" },
                NeoTreeGitDeleted = { fg = "#fb4934" },
                NeoTreeGitConflict = { fg = "#fe8019", bold = true },
                NeoTreeGitIgnored = { fg = "#665c54" },
              }

              for group, value in pairs(groups) do
                vim.api.nvim_set_hl(0, group, value)
              end
            end

            vim.api.nvim_create_autocmd("ColorScheme", {
              desc = "Keep Neo-tree Git colours after a colorscheme change",
              callback = apply_git_highlights,
            })

            vim.api.nvim_create_autocmd("VimEnter", {
              callback = function()
                vim.schedule(function()
                  apply_git_highlights()
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
