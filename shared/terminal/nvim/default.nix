# shared/terminal/nvim/default.nix

# =====================================================================
# NEOVIM: SETTINGS KNOBS
#
# Theme, icons, language servers, linting, notifications, and the basic
# editor settings. Their option interfaces and the Lua they generate
# live in options/cli/nvim.
# =====================================================================

{ ... }:

{
  imports = [
    # Theme selection and each theme's values.
    ./theme.nix

    # Plugin knobs.
    ./plugins.nix

    # Keybinding knobs.
    ./keys.nix
  ];

  home.shared.terminal.nvim = {
    enable = true;

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Keeps the Python and Ruby remote-plugin providers available.
    pythonProvider = true;
    rubyProvider = true;

    # ---- CORE ---- #
    core = {
      leader = " ";
      localLeader = ",";

      iconsEnabled = true;
      updateNotifications = true;

      pluginsDirectory = "plugins";

      autoSave = {
        enable = true;
        interval = 60000;
      };

      astronvim = {
        plugin = "AstroNvim/AstroNvim";
        version = "^6";
        import = "astronvim.plugins";
      };

      lazy = {
        repository = "https://github.com/folke/lazy.nvim.git";
        branch = "stable";

        lockfileName = "lazy-lock.json";

        # Copied in once, then owned by Lazy so :Lazy update keeps working.
        lockfileSource = ./lazy-lock.json;

        exportCommand = "nvim-export-lazy-lock";

        installColorschemes = [
          "gruvbox"
          "habamax"
        ];

        backdrop = 100;

        disabledPlugins = [
          "gzip"
          "netrwPlugin"
          "tarPlugin"
          "tohtml"
          "zipPlugin"
        ];
      };

      features = {
        autopairs = true;
        cmp = true;

        diagnostics = {
          virtual_text = true;
          virtual_lines = false;
        };

        highlighturl = true;
        notifications = true;
      };

      options.opt = {
        number = true;
        relativenumber = true;

        signcolumn = "yes";

        # Wraps text at word boundaries while keeping the source lines.
        wrap = true;
        linebreak = true;
        breakindent = true;
      };
    };

    # ---- ASTRONVIM STARTER FILES ---- #
    # Kept inert by upstream's guard line until one is edited.
    starter = {
      enable = true;

      directory = "nvim/lua/plugins";

      files = [
        "astrocore"
        "astrolsp"
        "astroui"
        "mason"
        "none-ls"
        "treesitter"
        "user"
      ];
    };

    # ---- ICONS ---- #
    icons.enable = true;

    # ---- LANGUAGE SERVERS ---- #
    lsp = {
      enable = true;

      servers = [
        "nixd"
        "ts_ls"
        "vue_ls"
        "gopls"
        "rust_analyzer"
        "pyright"
        "ruff"
        "jsonls"
        "yamlls"
        "taplo"
        "lua_ls"
      ];

      serverSettings = {
        nixd = {
          cmd = [ "nixd" ];
          filetypes = [ "nix" ];
        };

        gopls.settings.gopls = {
          gofumpt = true;
          staticcheck = true;

          analyses = {
            shadow = true;
            unusedparams = true;
          };
        };

        rust_analyzer.settings."rust-analyzer".check.command = "clippy";

        pyright.settings.pyright.disableOrganizeImports = true;

        lua_ls.settings.Lua = {
          diagnostics.globals = [ "vim" ];
          workspace.checkThirdParty = false;
        };

        yamlls.settings.yaml.keyOrdering = false;
      };
    };

    # ---- LINTING ---- #
    lint = {
      enable = true;

      events = [
        "BufEnter"
        "BufWritePost"
        "InsertLeave"
      ];

      lintersByFiletype = {
        go = [ "golangcilint" ];
        javascript = [ "eslint_d" ];
        javascriptreact = [ "eslint_d" ];
        lua = [ "selene" ];
        typescript = [ "eslint_d" ];
        typescriptreact = [ "eslint_d" ];
        vue = [ "eslint_d" ];
        yaml = [ "yamllint" ];
      };
    };
  };
}
