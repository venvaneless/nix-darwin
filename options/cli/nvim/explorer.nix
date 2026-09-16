# options/cli/nvim/explorer.nix
#
# =====================================================================
# OPTIONS: NEOVIM FILE EXPLORER
#
# Declares the Neo-tree sidebar knobs and writes their Lua file.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  explorer = cfg.explorer;

  colour = name: explorer.palette.${name} or name;

  gitHighlights = lib.mapAttrs (
    _: entry:
    { fg = colour entry.fg; } // lib.optionalAttrs entry.bold { bold = true; }
  ) explorer.gitHighlights;

  componentConfig = {
    # Colour the file name itself by Git state, not only the symbol.
    name.use_git_status_colors = explorer.colourNamesByGitStatus;

    git_status = {
      symbols = explorer.gitSymbols;
      align = explorer.gitSymbolAlignment;
    };

    last_modified.enabled = explorer.showLastModified;
  };

  explorerOptions = ''
    function(_, opts)
      opts.enable_git_status = ${lua.render "  " explorer.gitStatus}
      opts.git_status_async = ${lua.render "  " explorer.gitStatusAsync}

      opts.filesystem = vim.tbl_deep_extend("force", opts.filesystem or {}, ${
        lua.render "  " {
          follow_current_file.enabled = explorer.followCurrentFile;

          filtered_items = {
            visible = explorer.showFilteredItems;
            hide_dotfiles = !explorer.showDotfiles;
            hide_gitignored = !explorer.showGitIgnored;
          };
        }
      })

      opts.window = vim.tbl_deep_extend("force", opts.window or {}, ${
        lua.render "  " { inherit (explorer) position width; }
      })

      opts.default_component_configs = vim.tbl_deep_extend(
        "force",
        opts.default_component_configs or {},
        ${lua.render "    " componentConfig}
      )

      return opts
    end
  '';

  explorerInit = ''
    function()
      local function apply_git_highlights()
        local groups = ${lua.render "    " gitHighlights}

        for group, value in pairs(groups) do
          vim.api.nvim_set_hl(0, group, value)
        end
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        desc = "Keep Neo-tree Git colours after a colorscheme change",
        callback = apply_git_highlights,
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.schedule(function()
            apply_git_highlights()
            ${lib.optionalString explorer.openOnStart ''vim.cmd("Neotree show")''}
          end)
        end,
      })

      ${lib.optionalString explorer.refreshOnFocus ''
        vim.api.nvim_create_autocmd("FocusGained", {
          desc = "Refresh Neo-tree Git status when Neovim regains focus",
          callback = function()
            local manager = package.loaded["neo-tree.sources.manager"]
            if manager then manager.refresh("filesystem") end
          end,
        })
      ''}
    end
  '';
in
{
  options.home.shared.terminal.nvim.explorer = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show the project sidebar.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "nvim-neo-tree/neo-tree.nvim";
      description = "Plugin providing the sidebar.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/explorer.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    position = lib.mkOption {
      type = lib.types.str;
      default = "left";
      description = "Side of the editor the sidebar opens on.";
    };

    width = lib.mkOption {
      type = lib.types.int;
      default = 36;
      description = "Sidebar width in columns.";
    };

    openOnStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the sidebar when Neovim starts.";
    };

    followCurrentFile = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Reveal the file being edited in the tree.";
    };

    showFilteredItems = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show items the filters would otherwise hide.";
    };

    showDotfiles = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "List files whose names begin with a dot.";
    };

    showGitIgnored = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "List files Git ignores.";
    };

    gitStatus = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Mark each file with its Git state.";
    };

    gitStatusAsync = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Collect the Git state in the background.";
    };

    refreshOnFocus = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Refresh the Git state when Neovim regains focus, so outside changes show up.";
    };

    colourNamesByGitStatus = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Colour the file name by its Git state, not only its symbol.";
    };

    showLastModified = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show each file's age, at the cost of name width.";
    };

    gitSymbols = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ added = "+"; modified = "~"; }'';
      description = "Label shown for each Git state.";
    };

    gitSymbolAlignment = lib.mkOption {
      type = lib.types.str;
      default = "right";
      description = "Which side of the row the Git labels sit on.";
    };

    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Named colours the Git highlights use.";
    };

    gitHighlights = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            fg = lib.mkOption {
              type = lib.types.str;
              description = "Palette name or hex colour for this Git state.";
            };

            bold = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Draw the entry in bold.";
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''{ NeoTreeGitAdded = { fg = "green"; }; }'';
      description = "Colour of each Neo-tree Git highlight group.";
    };
  };

  config = lib.mkIf (cfg.enable && explorer.enable) {
    xdg.configFile.${explorer.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ explorer.plugin ];

        opts = lua.raw explorerOptions;
        init = lua.raw explorerInit;
      }
    ];
  };
}
