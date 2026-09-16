# shared/terminal/nvim/keys.nix

# =====================================================================
# NEOVIM: KEYBINDING KNOBS
#
# Every shared Neovim mapping, including the ones each plugin owns.
# Their option interfaces and generated Lua live in options/cli/nvim.
# =====================================================================

{ ... }:

{
  home.shared.terminal.nvim = {
    keys = {
      # ---- NORMAL MODE ---- #
      normal = {
        saveFile = {
          key = "<C-s>";
          command = "<cmd>w<cr>";
          description = "Save file";
        };

        closeBuffer = {
          key = "<Leader>q";
          command = "<cmd>bd<cr>";
          description = "Close buffer";
        };

        toggleExplorer = {
          key = "<Leader>e";
          command = "<cmd>Neotree toggle<cr>";
          description = "Toggle file explorer";
        };

        findFiles = {
          key = "<Leader>ff";
          command = "<cmd>Telescope find_files<cr>";
          description = "Find files";
        };

        findText = {
          key = "<Leader>fg";
          command = "<cmd>Telescope live_grep<cr>";
          description = "Find text";
        };

        findBuffers = {
          key = "<Leader>fb";
          command = "<cmd>Telescope buffers<cr>";
          description = "Find buffers";
        };

        findHelp = {
          key = "<Leader>fh";
          command = "<cmd>Telescope help_tags<cr>";
          description = "Find help";
        };

        nextBuffer = {
          key = "]b";
          lua = ''require("astrocore.buffer").nav(vim.v.count1)'';
          description = "Next buffer";
        };

        previousBuffer = {
          key = "[b";
          lua = ''require("astrocore.buffer").nav(-vim.v.count1)'';
          description = "Previous buffer";
        };
      };

      # ---- INSERT MODE ---- #
      insert = {
        exitInsertMode = {
          key = "jk";
          command = "<Esc>";
          description = "Exit insert mode";
        };
      };

      # ---- GIT ---- #
      # Read by the Gitsigns module; AstroNvim owns <Leader>gl and <Leader>gL.
      toggleLineBlame = "<Leader>gb";
    };

    # ---- BREADCRUMBS ---- #
    dropbar.keymaps = {
      pick = {
        key = "<Leader>;";
        action = "pick";
        description = "Dropbar: Pick breadcrumb";
      };

      contextStart = {
        key = "[;";
        action = "goto_context_start";
        description = "Dropbar: Go to context start";
      };

      nextContext = {
        key = "];";
        action = "select_next_context";
        description = "Dropbar: Select next context";
      };
    };

    # ---- NOTIFICATIONS ---- #
    notify.keymaps = {
      history = {
        key = "<Leader>fn";
        action = "show_history";
        description = "Find notifications";
      };

      dismiss = {
        key = "<Leader>un";
        action = "hide";
        description = "Dismiss notifications";
      };
    };

    # ---- PROJECTS ---- #
    projects.keymaps = {
      pick = {
        key = "<Leader>fp";
        action = "pick_project";
        description = "Find projects";
      };

      reloadSession = {
        key = "<Leader>fP";
        action = "load_dirsession";
        description = "Reload project session";
      };
    };
  };
}
