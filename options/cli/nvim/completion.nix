# options/cli/nvim/completion.nix
#
# =====================================================================
# OPTIONS: NEOVIM COMPLETION
#
# Declares the completion and inline suggestion knobs and writes their
# Lua file.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  completion = cfg.completion;
  copilot = completion.copilot;

  renderKeymap = keys: lua.render "      " keys;

  copilotSpec = {
    __positional = [ copilot.plugin ];

    cmd = copilot.command;
    event = copilot.event;
    build = copilot.build;

    opts.suggestion = {
      enabled = true;
      auto_trigger = copilot.autoTrigger;
      hide_during_completion = copilot.hideDuringCompletion;

      keymap.accept = false;
    };

    # The suggestion is accepted through the completion plugin's own key,
    # so both know which one wins.
    specs = [
      {
        __positional = [ "AstroNvim/astrocore" ];

        opts.options.g.ai_accept = lua.raw ''
          function()
            if require("copilot.suggestion").is_visible() then
              require("copilot.suggestion").accept()
              return true
            end
          end
        '';
      }

      {
        __positional = [ completion.plugin ];

        optional = true;

        opts = lua.raw ''
          function(_, opts)
            opts.keymap = opts.keymap or {}

            opts.keymap["${copilot.acceptKey}"] = ${renderKeymap [
              "snippet_forward"
              (lua.raw ''
                function()
                  if vim.g.ai_accept then
                    return vim.g.ai_accept()
                  end
                end
              '')
              "fallback"
            ]}

            opts.keymap["${copilot.previousKey}"] = ${renderKeymap [ "snippet_backward" "fallback" ]}
          end
        '';
      }
    ];
  };
in
{
  options.home.shared.terminal.nvim.completion = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure the completion menu and inline suggestions.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "saghen/blink.cmp";
      description = "Plugin providing the completion menu.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/completion.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    ghostText = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Preview the selected completion inline, in grey.";
    };

    copilot = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show GitHub Copilot's inline suggestions.";
      };

      plugin = lib.mkOption {
        type = lib.types.str;
        default = "zbirenbaum/copilot.lua";
        description = "Plugin providing the suggestions.";
      };

      command = lib.mkOption {
        type = lib.types.str;
        default = "Copilot";
        description = "Command that loads the plugin.";
      };

      event = lib.mkOption {
        type = lib.types.str;
        default = "InsertEnter";
        description = "Event that starts Copilot, so it is ready before typing.";
      };

      build = lib.mkOption {
        type = lib.types.str;
        default = ":Copilot auth";
        description = "Command run after the plugin is installed.";
      };

      autoTrigger = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Suggest without being asked.";
      };

      hideDuringCompletion = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Hide suggestions while the completion menu is open.";
      };

      acceptKey = lib.mkOption {
        type = lib.types.str;
        default = "<Tab>";
        description = "Key that expands a snippet, accepts a suggestion, or falls through.";
      };

      previousKey = lib.mkOption {
        type = lib.types.str;
        default = "<S-Tab>";
        description = "Key that jumps back through a snippet.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && completion.enable) {
    xdg.configFile.${completion.relativePath}.text = lua.renderSpecs (
      [
        {
          __positional = [ completion.plugin ];

          opts.completion.ghost_text.enabled = completion.ghostText;
        }
      ]
      ++ lib.optional copilot.enable copilotSpec
    );
  };
}
