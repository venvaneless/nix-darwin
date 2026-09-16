# options/cli/nvim/git.nix
#
# =====================================================================
# OPTIONS: NEOVIM GIT
#
# Declares the Gitsigns knobs and writes their Lua file. The heirline
# statusline reads b:gitsigns_status_dict, so this module owns the signs.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  git = cfg.git;

  signsSpec = {
    __positional = [ git.plugin ];

    opts = {
      signcolumn = git.signColumn;
      linehl = git.lineHighlight;
      attach_to_untracked = git.attachToUntracked;

      watch_gitdir = {
        enable = git.watchGitDirectory;
        follow_files = git.followFiles;
      };

      signs = lib.mapAttrs (_: text: { inherit text; }) git.signs;

      current_line_blame = git.lineBlame.enable;

      current_line_blame_opts = {
        virt_text = true;
        virt_text_pos = git.lineBlame.position;
        delay = git.lineBlame.delay;
        ignore_whitespace = git.lineBlame.ignoreWhitespace;
      };

      current_line_blame_formatter = git.lineBlame.formatter;
    };

    # The configured line highlights need visible backgrounds, and a
    # colorscheme change resets them.
    config = lua.raw ''
      function(_, opts)
        require("gitsigns").setup(opts)

        local function apply_gitsigns_highlights()
          local groups = ${lua.render "      " (lib.mapAttrs (_: bg: { inherit bg; }) git.lineHighlightColours)}

          for group, value in pairs(groups) do
            vim.api.nvim_set_hl(0, group, value)
          end
        end

        vim.api.nvim_create_autocmd("ColorScheme", {
          desc = "Keep visible Gitsigns line highlights after theme changes",
          callback = apply_gitsigns_highlights,
        })

        vim.api.nvim_create_autocmd("VimEnter", {
          callback = function() vim.schedule(apply_gitsigns_highlights) end,
        })

        apply_gitsigns_highlights()
      end
    '';
  };

  blameMappingSpec = {
    __positional = [ "AstroNvim/astrocore" ];

    opts = lua.raw ''
      function(_, opts)
        opts.mappings = opts.mappings or {}
        opts.mappings.n = opts.mappings.n or {}

        opts.mappings.n["${cfg.keys.toggleLineBlame}"] = {
          function()
            require("gitsigns").toggle_current_line_blame()
          end,

          desc = "Toggle line blame",
        }

        return opts
      end
    '';
  };
in
{
  options.home.shared.terminal.nvim.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure Gitsigns change markers and line blame.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "lewis6991/gitsigns.nvim";
      description = "Plugin providing the Git signs and line blame.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/git.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    signs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ add = "▎"; delete = "▁"; }'';
      description = "Gutter marker for each kind of change.";
    };

    signColumn = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep a permanent gutter marker for changed lines.";
    };

    lineHighlight = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Tint changed lines in the buffer.";
    };

    attachToUntracked = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show markers in files Git does not track yet.";
    };

    watchGitDirectory = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Refresh the markers when the Git directory changes.";
    };

    followFiles = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep following a file across renames.";
    };

    lineBlame = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show who last changed the current line, at the end of the line.";
      };

      position = lib.mkOption {
        type = lib.types.str;
        default = "eol";
        description = "Where the blame text is drawn.";
      };

      delay = lib.mkOption {
        type = lib.types.int;
        default = 400;
        description = "Milliseconds the cursor must settle before Git is queried.";
      };

      ignoreWhitespace = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Skip whitespace-only changes when blaming.";
      };

      formatter = lib.mkOption {
        type = lib.types.str;
        default = "  <author>, <author_time:%R> — <summary>";
        description = "Format of the blame text.";
      };
    };

    lineHighlightColours = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ GitSignsAddLn = "#3a421a"; }'';
      description = "Background colour for each Gitsigns line highlight group.";
    };
  };

  config = lib.mkIf (cfg.enable && git.enable) {
    xdg.configFile.${git.relativePath}.text = lua.renderSpecs [
      signsSpec
      blameMappingSpec
    ];
  };
}
