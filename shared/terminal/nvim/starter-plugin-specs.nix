# shared/terminal/nvim/starter-plugin-specs.nix

# =====================================================================
# NEOVIM: ASTROVIM STARTER PLUGIN SPECS
#
# Restores the populated AstroNvim starter specifications as store-backed
# Home Manager links. Their guards keep their established behavior unchanged,
# while this repository owns their exact contents.
# =====================================================================

{
  config,
  lib,
  ...
}:

let
  # ---- ASTROCORE STARTER SPEC ---- #
  astrocoreConfig = ''
    if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

    -- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
    -- Configuration documentation can be found with `:h astrocore`
    -- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
    --       as this provides autocomplete and documentation while editing
    ---@type LazySpec
    return {
      "AstroNvim/astrocore",
      ---@type AstroCoreOpts
      opts = {
        -- Configure core features of AstroNvim
        features = {
          large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
          autopairs = true, -- enable autopairs at start
          cmp = true, -- enable completion at start
          diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
          highlighturl = true, -- highlight URLs at start
          notifications = true, -- enable notifications at start
        },
        -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
        diagnostics = {
          virtual_text = true,
          underline = true,
        },
        -- passed to `vim.filetype.add`
        filetypes = {
          -- see `:h vim.filetype.add` for usage
          extension = {
            foo = "fooscript",
          },
          filename = {
            [".foorc"] = "fooscript",
          },
          pattern = {
            [".*/etc/foo/.*"] = "fooscript",
          },
        },
        -- vim options can be configured here
        options = {
          opt = { -- vim.opt.<key>
            relativenumber = true, -- sets vim.opt.relativenumber
            number = true, -- sets vim.opt.number
            spell = false, -- sets vim.opt.spell
            signcolumn = "yes", -- sets vim.opt.signcolumn to yes
            wrap = false, -- sets vim.opt.wrap
          },
          g = { -- vim.g.<key>
            -- configure global vim variables (vim.g)
            -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
            -- This can be found in the `lua/lazy_setup.lua` file
          },
        },
        -- Mappings can be configured through AstroCore as well.
        -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
        mappings = {
          -- first key is the mode
          n = {
            -- second key is the lefthand side of the map
            -- navigate buffer tabs
            ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
            ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
            -- mappings seen under group name "Buffer"
            ["<Leader>bd"] = {
              function()
                require("astroui.status.heirline").buffer_picker(
                  function(bufnr) require("astrocore.buffer").close(bufnr) end
                )
              end,
              desc = "Close buffer from tabline",
            },

            -- tables with just a `desc` key will be registered with which-key if it's installed
            -- this is useful for naming menus
            -- ["<Leader>b"] = { desc = "Buffers" },
            -- setting a mapping to false will disable it
            -- ["<C-S>"] = false,
          },
        },
      },
    }
  '';

  # ---- ASTROLSP STARTER SPEC ---- #
  astrolspConfig = ''
    if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

    -- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
    -- Configuration documentation can be found with `:h astrolsp`
    -- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
    --       as this provides autocomplete and documentation while editing
    ---@type LazySpec
    return {
      "AstroNvim/astrolsp",
      ---@type AstroLSPOpts
      opts = {
        -- Configuration table of features provided by AstroLSP
        features = {
          codelens = true, -- enable/disable codelens refresh on start
          inlay_hints = false, -- enable/disable inlay hints on start
          semantic_tokens = true, -- enable/disable semantic token highlighting
        },
        -- customize lsp formatting options
        formatting = {
          -- control auto formatting on save
          format_on_save = {
            enabled = true, -- enable or disable format on save globally
            allow_filetypes = { -- enable format on save for specified filetypes only
              -- "go",
            },
            ignore_filetypes = { -- disable format on save for specified filetypes
              -- "python",
            },
          },
          disabled = { -- disable formatting capabilities for the listed language servers
            -- disable lua_ls formatting capability if you want to use StyLua to format your lua code
            -- "lua_ls",
          },
          timeout_ms = 1000, -- default format timeout
          -- filter = function(client) -- fully override the default formatting function
          --   return true
          -- end
        },
        -- enable servers that you already have installed without mason
        servers = {
          -- "pyright"
        },
        -- customize language server configuration passed to `vim.lsp.config`
        -- client specific configuration can also go in `lsp/` in your configuration root (see `:h lsp-config`)
        config = {
          -- ["*"] = { capabilities = {} }, -- modify default LSP client settings such as capabilities
        },
        -- customize how language servers are attached
        handlers = {
          -- a function with the key `*` modifies the default handler, functions takes the server name as the parameter
          -- ["*"] = function(server) vim.lsp.enable(server) end
          -- the key is the server that is being setup with `vim.lsp.config`
          -- rust_analyzer = false, -- setting a handler to false will disable the set up of that language server
        },
        -- Configure buffer local auto commands to add when attaching a language server
        autocmds = {
          -- first key is the `augroup` to add the auto commands to (:h augroup)
          lsp_codelens_refresh = {
            -- Optional condition to create/delete auto command group
            -- can either be a string of a client capability or a function of `fun(client, bufnr): boolean`
            -- condition will be resolved for each client on each execution and if it ever fails for all clients,
            -- the auto commands will be deleted for that buffer
            cond = "textDocument/codeLens",
            -- cond = function(client, bufnr) return client.name == "lua_ls" end,
            -- list of auto commands to set
            {
              -- events to trigger
              event = { "InsertLeave", "BufEnter" },
              -- the rest of the autocmd options (:h nvim_create_autocmd)
              desc = "Refresh codelens (buffer)",
              callback = function(args)
                if require("astrolsp").config.features.codelens then vim.lsp.codelens.enable(true, { bufnr = args.buf }) end
              end,
            },
          },
        },
        -- mappings to be set up on attaching of a language server
        mappings = {
          n = {
            -- a `cond` key can provided as the string of a server capability to be required to attach, or a function of `client` to be required to attach
            gD = {
              function() vim.lsp.buf.declaration() end,
              desc = "Declaration of current symbol",
              cond = "textDocument/declaration",
            },
            ["<Leader>uY"] = {
              function() require("astrolsp.toggles").buffer_semantic_tokens() end,
              desc = "Toggle LSP semantic highlight (buffer)",
              cond = function(client)
                return client:supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
              end,
            },
          },
        },
        -- A custom `on_attach` function to be run after the default `on_attach` function
        -- takes two parameters `client` and `bufnr`  (`:h lsp-attach`)
        on_attach = function(client, bufnr)
          -- this would disable semanticTokensProvider for all clients
          -- client.server_capabilities.semanticTokensProvider = nil
        end,
      },
    }
  '';

  # ---- ASTROUI STARTER SPEC ---- #
  astrouiConfig = ''
    if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

    -- AstroUI provides the basis for configuring the AstroNvim User Interface
    -- Configuration documentation can be found with `:h astroui`
    -- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
    --       as this provides autocomplete and documentation while editing
    ---@type LazySpec
    return {
      "AstroNvim/astroui",
      ---@type AstroUIOpts
      opts = {
        -- change colorscheme
        colorscheme = "astrodark",
        -- AstroUI allows you to easily modify highlight groups easily for any and all colorschemes
        highlights = {
          init = { -- this table overrides highlights in all themes
            -- Normal = { bg = "#000000" },
          },
          astrodark = { -- a table of overrides/changes when applying the astrotheme theme
            -- Normal = { bg = "#000000" },
          },
        },
        -- Icons can be configured throughout the interface
        icons = {
          -- configure the loading of the lsp in the status line
          LSPLoading1 = "⠋",
          LSPLoading2 = "⠙",
          LSPLoading3 = "⠹",
          LSPLoading4 = "⠸",
          LSPLoading5 = "⠼",
          LSPLoading6 = "⠴",
          LSPLoading7 = "⠦",
          LSPLoading8 = "⠧",
          LSPLoading9 = "⠇",
          LSPLoading10 = "⠏",
        },
      },
    }
  '';

  # ---- MASON STARTER SPEC ---- #
  masonConfig = ''
    if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

    -- Customize Mason

    ---@type LazySpec
    return {
      -- use mason-tool-installer for automatically installing Mason packages
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        -- overrides `require("mason-tool-installer").setup(...)`
        opts = {
          -- Make sure to use the names found in `:Mason`
          ensure_installed = {
            -- install language servers
            "lua-language-server",
            -- install formatters
            "stylua",

            -- install debuggers
            "debugpy",

            -- install any other package
            "tree-sitter-cli",
          },
        },
      },
    }
  '';

  # ---- NONE-LS STARTER SPEC ---- #
  noneLsConfig = ''
    if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

    -- Customize None-ls sources

    ---@type LazySpec
    return {
      "nvimtools/none-ls.nvim",
      opts = function(_, opts)
        -- opts variable is the default configuration table for the setup function call
        -- local null_ls = require "null-ls"
        -- Check supported formatters and linters
        -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/formatting
        -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
        -- Only insert new sources, do not replace the existing ones
        -- (If you wish to replace, use `opts.sources = {}` instead of the `list_insert_unique` function)
        opts.sources = require("astrocore").list_insert_unique(opts.sources, {
          -- Set a formatter
          -- null_ls.builtins.formatting.stylua,
          -- null_ls.builtins.formatting.prettier,
        })
      end,
    }
  '';

  # ---- TREESITTER STARTER SPEC ---- #
  treesitterConfig = ''
    if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

    -- Customize Treesitter
    -- --------------------
    -- Treesitter customizations are handled with AstroCore
    -- as nvim-treesitter simply provides a download utility for parsers
    ---@type LazySpec
    return {
      "AstroNvim/astrocore",
      ---@type AstroCoreOpts
      opts = {
        treesitter = {
          highlight = true, -- enable/disable treesitter based highlighting
          indent = true, -- enable/disable treesitter based indentation
          auto_install = true, -- enable/disable automatic installation of detected languages
          ensure_installed = {
            "lua",
            "vim",
            -- add more arguments for adding more treesitter parsers
          },
        },
      },
    }
  '';

  # ---- USER STARTER SPEC ---- #
  userConfig = ''
    if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

    -- You can also add or configure plugins by creating files in this `plugins/` folder
    -- PLEASE REMOVE THE EXAMPLES YOU HAVE NO INTEREST IN BEFORE ENABLING THIS FILE
    -- Here are some examples:

    ---@type LazySpec
    return {

      -- == Examples of Adding Plugins ==

      "andweeb/presence.nvim",
      {
        "ray-x/lsp_signature.nvim",
        event = "BufRead",
        config = function() require("lsp_signature").setup() end,
      },
      -- == Examples of Overriding Plugins ==
      -- customize dashboard options
      {
        "folke/snacks.nvim",
        opts = {
          dashboard = {
            preset = {
              header = table.concat({
                " █████  ███████ ████████ ██████   ██████ ",
                "██   ██ ██         ██    ██   ██ ██    ██",
                "███████ ███████    ██    ██████  ██    ██",
                "██   ██      ██    ██    ██   ██ ██    ██",
                "██   ██ ███████    ██    ██   ██  ██████ ",
                "",
                "███    ██ ██    ██ ██ ███    ███",
                "████   ██ ██    ██ ██ ████  ████",
                "██ ██  ██ ██    ██ ██ ██ ████ ██",
                "██  ██ ██  ██  ██  ██ ██  ██  ██",
                "██   ████   ████   ██ ██      ██",
              }, "\n"),
            },
          },
        },
      },
      -- You can disable default plugins as follows:
      { "max397574/better-escape.nvim", enabled = false },

      -- You can also easily customize additional setup of plugins that is outside of the plugin's setup call
      {
        "L3MON4D3/LuaSnip",
        config = function(plugin, opts)
          -- add more custom luasnip configuration such as filetype extend or custom snippets
          local luasnip = require "luasnip"
          luasnip.filetype_extend("javascript", { "javascriptreact" })
          -- include the default astronvim config that calls the setup call
          require "astronvim.plugins.configs.luasnip"(plugin, opts)
        end,
      },
      {
        "windwp/nvim-autopairs",
        config = function(plugin, opts)
          require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
          -- add more custom autopairs configuration such as custom rules
          local npairs = require "nvim-autopairs"
          local Rule = require "nvim-autopairs.rule"
          local cond = require "nvim-autopairs.conds"
          npairs.add_rules(
            {
              Rule("$", "$", { "tex", "latex" })
                -- don't add a pair if the next character is %
                :with_pair(cond.not_after_regex "%%")
                -- don't add a pair if the previous character is xxx
                :with_pair(
                  cond.not_before_regex("xxx", 3)
                )
                -- don't move right when repeat character
                :with_move(cond.none())
                -- don't delete if the next character is xx
                :with_del(cond.not_after_regex "xx")
                -- disable adding a newline when you press <cr>
                :with_cr(cond.none()),
            },
            -- disable for .vim files, but it work for another filetypes
            Rule("a", "a", "-vim")
          )
        end,
      },
    }
  '';
in
{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile = {
      # ---- ASTROVIM STARTER SPECS ---- #
      # Restores the exact populated specs as Nix-managed configuration files.
      "nvim/lua/plugins/astrocore.lua".text = astrocoreConfig;
      "nvim/lua/plugins/astrolsp.lua".text = astrolspConfig;
      "nvim/lua/plugins/astroui.lua".text = astrouiConfig;
      "nvim/lua/plugins/mason.lua".text = masonConfig;
      "nvim/lua/plugins/none-ls.lua".text = noneLsConfig;
      "nvim/lua/plugins/treesitter.lua".text = treesitterConfig;
      "nvim/lua/plugins/user.lua".text = userConfig;
    };
  };
}
