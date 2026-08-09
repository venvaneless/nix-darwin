# shared/terminal/nvim/lint.nix

# =====================================================================
# NEOVIM: LINTING
#
# Project-aware diagnostics from Nix-managed command-line linters.
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/lint.lua".text = ''
      return {
        {
          "mfussenegger/nvim-lint",

          event = {
            "BufEnter",
            "BufWritePost",
            "InsertLeave",
          },

          config = function()
            local lint = require("lint")

            lint.linters_by_ft = {
              javascript = {
                "eslint_d",
              },

              javascriptreact = {
                "eslint_d",
              },

              typescript = {
                "eslint_d",
              },

              typescriptreact = {
                "eslint_d",
              },

              vue = {
                "eslint_d",
              },

              go = {
                "golangcilint",
              },

              lua = {
                "selene",
              },

              yaml = {
                "yamllint",
              },
            }

            local lint_group = vim.api.nvim_create_augroup("nvim_lint", {
              clear = true,
            })

            vim.api.nvim_create_autocmd({
              "BufEnter",
              "BufWritePost",
              "InsertLeave",
            }, {
              group = lint_group,
              callback = function()
                lint.try_lint()
              end,
            })
          end,
        },
      }
    '';
  };
}
