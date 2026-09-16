# options/cli/nvim/lint.nix
#
# =====================================================================
# OPTIONS: NEOVIM LINTING
#
# Declares the linter knobs and writes their Lua file.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  lint = cfg.lint;
in
{
  options.home.shared.terminal.nvim.lint = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run command-line linters and show their diagnostics.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "mfussenegger/nvim-lint";
      description = "Plugin running the linters.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/lint.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    events = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "BufEnter" "BufWritePost" "InsertLeave" ];
      description = "Neovim events that trigger a lint run.";
    };

    lintersByFiletype = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      example = lib.literalExpression ''{ lua = [ "selene" ]; }'';
      description = "Linters run for each file type.";
    };
  };

  config = lib.mkIf (cfg.enable && lint.enable) {
    xdg.configFile.${lint.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ lint.plugin ];

        event = lint.events;

        config = lua.raw ''
          function()
            local lint = require("lint")

            lint.linters_by_ft = ${lua.render "    " lint.lintersByFiletype}

            local lint_group = vim.api.nvim_create_augroup("nvim_lint", {
              clear = true,
            })

            vim.api.nvim_create_autocmd(${lua.render "    " lint.events}, {
              group = lint_group,
              callback = function()
                lint.try_lint()
              end,
            })
          end
        '';
      }
    ];
  };
}
