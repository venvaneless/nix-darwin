# options/cli/nvim/default.nix
#
# =====================================================================
# OPTIONS: NEOVIM
#
# Declares Neovim's own knobs, installs it, and writes the AstroNvim
# bootstrap, the Lazy setup, and the core settings from those knobs.
# Every value lives in shared/terminal/nvim.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  core = cfg.core;

  nvimConfigDirectory = "${config.xdg.configHome}/nvim";
  lazyLockFile = "${nvimConfigDirectory}/${core.lazy.lockfileName}";

  # Lazy owns the runtime lockfile, so it is seeded once and left alone.
  # This keeps :Lazy update working and its result committable.
  exportLazyLock = pkgs.writeShellScriptBin core.lazy.exportCommand ''
    set -euo pipefail

    if [ ! -f "${lazyLockFile}" ]; then
      echo "Error: Lazy lockfile not found at ${lazyLockFile}." >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/cat "${lazyLockFile}"
  '';

  initLua = ''
    local lazypath = vim.env.LAZY
      or vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

    if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
      local result = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "${core.lazy.repository}",
        "--branch=${core.lazy.branch}",
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
  ''
  + lib.optionalString core.autoSave.enable ''

    -- Saves every modified normal file buffer once per interval.
    vim.fn.timer_start(${toString core.autoSave.interval}, function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf)
          and vim.bo[buf].modified
          and vim.bo[buf].buftype == ""
          and vim.api.nvim_buf_get_name(buf) ~= "" then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent write")
          end)
        end
      end
    end, { ["repeat"] = -1 })
  '';

  lazySetupLua = ''
    require("lazy").setup(${
      lua.render "" [
        {
          __positional = [ core.astronvim.plugin ];

          version = core.astronvim.version;
          import = core.astronvim.import;

          opts = {
            mapleader = core.leader;
            maplocalleader = core.localLeader;

            icons_enabled = core.iconsEnabled;
            update_notifications = core.updateNotifications;
          };
        }

        { import = core.pluginsDirectory; }
      ]
    }, ${
      lua.render "" {
        install.colorscheme = core.lazy.installColorschemes;
        ui.backdrop = core.lazy.backdrop;
        performance.rtp.disabled_plugins = core.lazy.disabledPlugins;
      }
    })
  '';
in
{
  imports = [
    # Theme knob schema, theme selector, and the selected theme's Lua.
    ./themes/helper.nix

    ./completion.nix
    ./dropbar.nix
    ./explorer.nix
    ./git.nix
    ./heirline.nix
    ./icons.nix
    ./keys.nix
    ./lint.nix
    ./lsp.nix
    ./notify.nix
    ./projects.nix
    ./starter.nix
    ./telescope.nix
  ];

  options.home.shared.terminal.nvim = {
    enable = lib.mkEnableOption "Neovim and AstroNvim configuration";

    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Make Neovim the editor other tools open.";
    };

    viAlias = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Also answer to vi.";
    };

    vimAlias = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Also answer to vim.";
    };

    pythonProvider = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep the Python remote-plugin provider available.";
    };

    rubyProvider = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep the Ruby remote-plugin provider available.";
    };

    neovide.enable = lib.mkEnableOption "Neovide graphical Neovim client";

    core = {
      relativePath = lib.mkOption {
        type = lib.types.str;
        default = "nvim/lua/plugins/core.lua";
        description = "Config-relative Lua file the core settings are written to.";
      };

      initPath = lib.mkOption {
        type = lib.types.str;
        default = "nvim/init.lua";
        description = "Config-relative file Neovim reads first.";
      };

      lazySetupPath = lib.mkOption {
        type = lib.types.str;
        default = "nvim/lua/lazy_setup.lua";
        description = "Config-relative file that sets Lazy up.";
      };

      leader = lib.mkOption {
        type = lib.types.str;
        default = " ";
        description = "Leader key.";
      };

      localLeader = lib.mkOption {
        type = lib.types.str;
        default = ",";
        description = "Local leader key.";
      };

      iconsEnabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Let AstroNvim draw icons.";
      };

      updateNotifications = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Tell me when AstroNvim has an update.";
      };

      pluginsDirectory = lib.mkOption {
        type = lib.types.str;
        default = "plugins";
        description = "Lua module Lazy imports the plugin files from.";
      };

      autoSave = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Save modified file buffers on a timer.";
        };

        interval = lib.mkOption {
          type = lib.types.int;
          default = 60000;
          description = "Milliseconds between automatic saves.";
        };
      };

      astronvim = {
        plugin = lib.mkOption {
          type = lib.types.str;
          default = "AstroNvim/AstroNvim";
          description = "AstroNvim repository.";
        };

        version = lib.mkOption {
          type = lib.types.str;
          default = "^6";
          description = "AstroNvim version Lazy installs.";
        };

        import = lib.mkOption {
          type = lib.types.str;
          default = "astronvim.plugins";
          description = "AstroNvim module Lazy imports.";
        };
      };

      lazy = {
        repository = lib.mkOption {
          type = lib.types.str;
          default = "https://github.com/folke/lazy.nvim.git";
          description = "Where Lazy is cloned from on first start.";
        };

        branch = lib.mkOption {
          type = lib.types.str;
          default = "stable";
          description = "Lazy branch that is cloned.";
        };

        lockfileName = lib.mkOption {
          type = lib.types.str;
          default = "lazy-lock.json";
          description = "Lockfile Lazy writes plugin revisions to.";
        };

        lockfileSource = lib.mkOption {
          type = lib.types.path;
          description = "Lockfile copied in the first time, then left to Lazy.";
        };

        exportCommand = lib.mkOption {
          type = lib.types.str;
          default = "nvim-export-lazy-lock";
          description = "Command that prints the runtime lockfile so it can be committed.";
        };

        installColorschemes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Colorschemes Lazy's own installer may use.";
        };

        backdrop = lib.mkOption {
          type = lib.types.int;
          default = 100;
          description = "Opacity of the backdrop behind Lazy's window.";
        };

        disabledPlugins = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Built-in Neovim plugins Lazy switches off.";
        };
      };

      features = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        example = lib.literalExpression ''{ autopairs = true; }'';
        description = "AstroNvim features, written into astrocore's features table.";
      };

      options = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        example = lib.literalExpression ''{ opt.number = true; }'';
        description = "Neovim options, written into astrocore's options table.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # ---- NEOVIM PACKAGE ---- #
    programs.neovim = {
      enable = true;

      inherit (cfg) defaultEditor viAlias vimAlias;

      withPython3 = cfg.pythonProvider;
      withRuby = cfg.rubyProvider;
    };

    # ---- NEOVIDE PACKAGE ---- #
    # Uses the same XDG Neovim configuration without a separate HOME wrapper.
    home.packages = [ exportLazyLock ] ++ lib.optional cfg.neovide.enable pkgs.neovide;

    # ---- MUTABLE LAZY STATE ---- #
    home.activation.initializeNvimLazyLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e "${lazyLockFile}" ]; then
        ''${DRY_RUN_CMD} ${pkgs.coreutils}/bin/install -Dm644 \
          "${core.lazy.lockfileSource}" \
          "${lazyLockFile}"
      fi
    '';

    xdg.configFile = {
      ${core.initPath}.text = initLua;

      ${core.lazySetupPath}.text = lazySetupLua;

      ${core.relativePath}.text = lua.renderSpecs [
        {
          __positional = [ "AstroNvim/astrocore" ];

          opts = {
            inherit (core) features options;
          };
        }
      ];
    };
  };
}
