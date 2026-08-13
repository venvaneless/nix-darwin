# shared/terminal/nvim/core.nix

# =====================================================================
# NEOVIM: CORE
#
# AstroNvim bootstrap and global configuration
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # ------------------------------------------------------------
  # ------ LAZY LOCKFILE ------ #
  #
  # Seeds the mutable runtime lockfile once, while keeping its
  # repository source available for reproducible plugin revisions.
  # ------------------------------------------------------------

  nvimConfigDir = "${config.xdg.configHome}/nvim";
  lazyLockFile = "${nvimConfigDir}/lazy-lock.json";
  lazyLockSource = ./lazy-lock.json;

  # ---- LOCKFILE EXPORTER ---- #
  # Prints the runtime lockfile so it can be committed back to this module.
  exportLazyLock = pkgs.writeShellScriptBin "nvim-export-lazy-lock" ''
    set -euo pipefail

    if [ ! -f "${lazyLockFile}" ]; then
      echo "Error: Lazy lockfile not found at ${lazyLockFile}." >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/cat "${lazyLockFile}"
  '';
in
{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    # ---- MUTABLE LAZY STATE ---- #
    # Lazy manages this runtime file, so Home Manager must not link it.
    home.activation.initializeNvimLazyLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e "${lazyLockFile}" ]; then
        ''${DRY_RUN_CMD} ${pkgs.coreutils}/bin/install -Dm644 \
          "${lazyLockSource}" \
          "${lazyLockFile}"
      fi
    '';

    # ---- LOCKFILE UPDATE HELPER ---- #
    # Run `nvim-export-lazy-lock > shared/terminal/nvim/lazy-lock.json`
    # from the repository after `:Lazy update` and testing the result.
    home.packages = [
      exportLazyLock
    ];

    xdg.configFile."nvim/init.lua".text = ''
      local lazypath = vim.env.LAZY
        or vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

      if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
        local result = vim.fn.system({
          "git",
          "clone",
          "--filter=blob:none",
          "https://github.com/folke/lazy.nvim.git",
          "--branch=stable",
          lazypath,
        })

        if vim.v.shell_error ~= 0 then
          vim.api.nvim_echo({
            {
              ("Error cloning lazy.nvim:\n%s\n"):format(result),
              "ErrorMsg",
            },
          }, true, {})

          vim.fn.getchar()
          vim.cmd.quit()
        end
      end

      vim.opt.rtp:prepend(lazypath)

      require("lazy_setup")
    '';

    xdg.configFile."nvim/lua/lazy_setup.lua".text = ''
      require("lazy").setup({
        {
          "AstroNvim/AstroNvim",

          version = "^6",

          import = "astronvim.plugins",

          opts = {
            mapleader = " ",
            maplocalleader = ",",

            icons_enabled = true,

            update_notifications = true,
          },
        },

        {
          import = "plugins",
        },
      }, {
        install = {
          colorscheme = {
            "gruvbox",
            "habamax",
          },
        },

        ui = {
          backdrop = 100,
        },

        performance = {
          rtp = {
            disabled_plugins = {
              "gzip",
              "netrwPlugin",
              "tarPlugin",
              "tohtml",
              "zipPlugin",
            },
          },
        },
      })
    '';

    xdg.configFile."nvim/lua/plugins/core.lua".text = ''
      return {
        {
          "AstroNvim/astrocore",

          opts = {
            features = {
              autopairs = true,
              cmp = true,

              diagnostics = {
                virtual_text = true,
                virtual_lines = false,
              },

              highlighturl = true,
              notifications = true,
            },

            options = {
              opt = {
                number = true,
                relativenumber = true,

                signcolumn = "yes",

                -- Wraps text at word boundaries while preserving source lines.
                wrap = true,
                linebreak = true,
                breakindent = true,
              },
            },
          },
        },
      }
    '';
  };
}
