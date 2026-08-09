# shared/terminal/nvim/lsp.nix

# =====================================================================
# NEOVIM: LSP
#
# Language server configuration for the shared development stack
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/lsp.lua".text = ''
      return {
        {
          "AstroNvim/astrolsp",

          opts = {
            servers = {
              "nixd",
              "ts_ls",
              "vue_ls",
              "gopls",
              "rust_analyzer",
              "pyright",
              "ruff",
              "jsonls",
              "yamlls",
              "taplo",
              "lua_ls",
            },

            config = {
              nixd = {
                cmd = {
                  "nixd",
                },

                filetypes = {
                  "nix",
                },
              },

              gopls = {
                settings = {
                  gopls = {
                    gofumpt = true,
                    staticcheck = true,

                    analyses = {
                      shadow = true,
                      unusedparams = true,
                    },
                  },
                },
              },

              rust_analyzer = {
                settings = {
                  ["rust-analyzer"] = {
                    check = {
                      command = "clippy",
                    },
                  },
                },
              },

              pyright = {
                settings = {
                  pyright = {
                    disableOrganizeImports = true,
                  },
                },
              },

              lua_ls = {
                settings = {
                  Lua = {
                    diagnostics = {
                      globals = {
                        "vim",
                      },
                    },

                    workspace = {
                      checkThirdParty = false,
                    },
                  },
                },
              },

              yamlls = {
                settings = {
                  yaml = {
                    keyOrdering = false,
                  },
                },
              },
            },
          },
        },
      }
    '';
  };
}
