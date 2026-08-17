# shared/terminal/nvim/git.nix

# =====================================================================
# NEOVIM: GIT
#
# Gitsigns line authorship and change timing
#
# The heirline statusline reads b:gitsigns_status_dict for the repo,
# branch, and diff counts, so this module owns the signs themselves.
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/git.lua".text = ''
      return {
        {
          "lewis6991/gitsigns.nvim",

          opts = {
            -- ---- CHANGE MARKERS ---- #
            -- Keep a permanent gutter marker and tint changed lines. This is
            -- intentionally stronger than the AstroNvim default so local
            -- changes remain obvious in Neovide as well as a terminal UI.
            signcolumn = true,
            linehl = true,
            attach_to_untracked = true,

            watch_gitdir = {
              enable = true,
              follow_files = true,
            },

            signs = {
              add = { text = "▎" },
              change = { text = "▎" },
              delete = { text = "▁" },
              topdelete = { text = "▔" },
              changedelete = { text = "~" },
              untracked = { text = "┆" },
            },

            -- ---- LINE BLAME ---- #
            -- Shows who last changed the current line and when, at the end
            -- of the line. This is the per-line answer to "when did this
            -- change"; Neo-tree's column answers it per file.
            current_line_blame = true,

            current_line_blame_opts = {
              virt_text = true,
              virt_text_pos = "eol",

              -- Wait until the cursor settles before querying git.
              delay = 400,

              ignore_whitespace = false,
            },

            current_line_blame_formatter = "  <author>, <author_time:%R> — <summary>",
          },

          config = function(_, opts)
            require("gitsigns").setup(opts)

            -- These backgrounds make the configured line highlights visible
            -- without sacrificing Gruvbox's contrast or readability.
            local function apply_gitsigns_highlights()
              local groups = {
                GitSignsAddLn = { bg = "#3a421a" },
                GitSignsChangeLn = { bg = "#4a3b16" },
                GitSignsDeleteLn = { bg = "#4a1f1d" },
                GitSignsChangedeleteLn = { bg = "#4a2b1c" },
                GitSignsTopdeleteLn = { bg = "#4a1f1d" },
                GitSignsUntrackedLn = { bg = "#3a421a" },
              }

              for group, value in pairs(groups) do
                vim.api.nvim_set_hl(0, group, value)
              end
            end

            vim.api.nvim_create_autocmd("ColorScheme", {
              desc = "Keep visible Gitsigns line highlights after theme changes",
              callback = apply_gitsigns_highlights,
            })

            vim.api.nvim_create_autocmd("VimEnter", {
              callback = function() vim.schedule(apply_gitsigns_highlights) end,
            })

            apply_gitsigns_highlights()
          end,
        },

        {
          "AstroNvim/astrocore",

          opts = function(_, opts)
            opts.mappings = opts.mappings or {}
            opts.mappings.n = opts.mappings.n or {}

            -- Toggle the inline blame text when it gets noisy.
            -- AstroNvim already owns <Leader>gl and <Leader>gL for one-off
            -- and full blame, so only the toggle is added here.
            opts.mappings.n["<Leader>gb"] = {
              function()
                require("gitsigns").toggle_current_line_blame()
              end,

              desc = "Toggle line blame",
            }

            return opts
          end,
        },
      }
    '';
  };
}
