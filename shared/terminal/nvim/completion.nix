# shared/terminal/nvim/completion.nix

# =====================================================================
# NEOVIM: COMPLETION
#
# Blink completion configuration and GitHub Copilot inline suggestions.
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/completion.lua".text = ''
      return {
        {
          "saghen/blink.cmp",

          opts = {
            completion = {
              ghost_text = {
                enabled = true,
              },
            },
          },
        },

        {
          "zbirenbaum/copilot.lua",

          cmd = "Copilot",
          # Starts Copilot before typing, including in a new buffer.
          event = "InsertEnter",
          build = ":Copilot auth",

          opts = {
            suggestion = {
              # Uses Copilot's inline virtual text instead of only its panel.
              enabled = true,
              auto_trigger = true,
              hide_during_completion = false,

              keymap = {
                accept = false,
              },
            },
          },

          specs = {
            {
              "AstroNvim/astrocore",

              opts = {
                options = {
                  g = {
                    ai_accept = function()
                      if require("copilot.suggestion").is_visible() then
                        require("copilot.suggestion").accept()
                        return true
                      end
                    end,
                  },
                },
              },
            },

            {
              "saghen/blink.cmp",

              optional = true,

              opts = function(_, opts)
                opts.keymap = opts.keymap or {}

                opts.keymap["<Tab>"] = {
                  "snippet_forward",
                  function()
                    if vim.g.ai_accept then
                      return vim.g.ai_accept()
                    end
                  end,
                  "fallback",
                }

                opts.keymap["<S-Tab>"] = {
                  "snippet_backward",
                  "fallback",
                }
              end,
            },
          },
        },
      }
    '';
  };
}
