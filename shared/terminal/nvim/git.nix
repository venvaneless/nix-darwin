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
