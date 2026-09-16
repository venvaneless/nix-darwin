# shared/terminal/nvim/plugins.nix

# =====================================================================
# NEOVIM: PLUGIN KNOBS
#
# Values for the plugins that draw the interface. Their option
# interfaces and generated Lua live in options/cli/nvim.
# =====================================================================

{ ... }:

{
  home.shared.terminal.nvim = {
    # ---- STATUSLINE ---- #
    statusline = {
      enable = true;

      palette = {
        bg0 = "#282828";
        bg1 = "#3c3836";
        fg1 = "#ebdbb2";
        gray = "#a89984";
        yellow = "#fabd2f";
        orange = "#fe8019";
        aqua = "#83a598";
        green = "#b8bb26";
        red = "#fb4934";
      };

      foreground = "fg1";
      background = "bg0";

      separator = "";
      reverseSeparator = "";

      order = [ "user" "shell" "language" "lsp" "git" "fill" "host" "clock" ];

      segments = {
        user = {
          icon = "";
          foreground = "bg0";
          background = "yellow";
          nextBackground = "orange";
          click = ''
            {
                  name = "heirline_user_click",
                  callback = function()
                    local value = vim.env.USER or vim.env.USERNAME or ""
                    vim.fn.setreg("+", value)
                    vim.notify("Copied user: " .. value)
                  end,
                }'';
        };

        shell = {
          icon = "";
          foreground = "bg0";
          background = "orange";
          nextBackground = "aqua";
          click = ''
            {
                  name = "heirline_shell_click",
                  callback = function()
                    vim.cmd("botright split | terminal " .. vim.o.shell)
                  end,
                }'';
        };

        language = {
          foreground = "bg0";
          background = "aqua";
          nextBackground = "green";
          click = ''
            {
                  name = "heirline_language_click",
                  callback = function()
                    language_cache[project_root()] = nil
                    vim.cmd("redrawstatus")
                  end,
                }'';
        };

        lsp = {
          icon = "";
          foreground = "bg0";
          background = "green";
          nextBackground = "bg1";
          updateEvents = [ "LspAttach" "LspDetach" "BufEnter" ];
          click = ''
            {
                  name = "heirline_lsp_click",
                  callback = function()
                    local names = attached_lsp_clients()

                    -- Restart through nvim-lspconfig when its commands exist,
                    -- otherwise stop the client and let the filetype
                    -- autocommand attach it again.
                    local function restart(name)
                      if vim.fn.exists(":LspRestart") == 2 then
                        vim.cmd("LspRestart " .. name)
                        return
                      end

                      for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
                        vim.lsp.stop_client(client.id, true)
                      end

                      vim.defer_fn(function()
                        vim.cmd("edit")
                      end, 500)
                    end

                    local function stop(name)
                      for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
                        vim.lsp.stop_client(client.id, true)
                      end

                      vim.notify("Stopped LSP: " .. name)
                    end

                    local actions = {}

                    for _, name in ipairs(names) do
                      table.insert(actions, {
                        label = "Restart  " .. name,
                        run = function() restart(name) end,
                      })
                      table.insert(actions, {
                        label = "Stop     " .. name,
                        run = function() stop(name) end,
                      })
                    end

                    table.insert(actions, {
                      label = "Start / re-attach for this buffer",
                      run = function()
                        if vim.fn.exists(":LspStart") == 2 then
                          vim.cmd("LspStart")
                        else
                          vim.cmd("edit")
                        end
                      end,
                    })

                    table.insert(actions, {
                      label = "Restart all attached servers",
                      run = function()
                        for _, name in ipairs(names) do
                          restart(name)
                        end
                      end,
                    })

                    table.insert(actions, {
                      label = "LSP info",
                      run = function()
                        if vim.fn.exists(":LspInfo") == 2 then
                          vim.cmd("LspInfo")
                        else
                          vim.cmd("checkhealth vim.lsp")
                        end
                      end,
                    })

                    table.insert(actions, {
                      label = "LSP log",
                      run = function()
                        vim.cmd("tabnew " .. vim.lsp.get_log_path())
                      end,
                    })

                    local title = #names > 0 and ("LSP: " .. table.concat(names, ", "))
                      or "LSP: nothing attached"

                    vim.ui.select(actions, {
                      prompt = title,
                      format_item = function(action)
                        return action.label
                      end,
                    }, function(choice)
                      if choice then
                        choice.run()
                      end
                    end)
                  end,
                }'';
        };

        host = {
          icon = "󰒋";
          foreground = "bg0";
          background = "yellow";
          previousBackground = "bg0";
          click = ''
            {
                  name = "heirline_host_click",
                  callback = function()
                    local hostname = vim.fn.hostname():gsub("%.local$", "")
                    vim.fn.setreg("+", hostname)
                    vim.notify("Copied host: " .. hostname)
                  end,
                }'';
        };

        clock = {
          icon = "";
          foreground = "bg0";
          background = "orange";
          previousBackground = "yellow";
          updateEvents = [ "CursorHold" "CursorHoldI" "BufEnter" ];
          click = ''
            {
                  name = "heirline_clock_click",
                  callback = function()
                    vim.notify(os.date("%A, %d %B %Y — %H:%M:%S"))
                  end,
                }'';
        };
      };

      languages = {
        nix = { name = "Nix"; icon = ""; };
        lua = { name = "Lua"; icon = ""; };
        ts = { name = "TypeScript"; icon = ""; };
        tsx = { name = "TypeScript"; icon = ""; };
        js = { name = "JavaScript"; icon = ""; };
        jsx = { name = "JavaScript"; icon = ""; };
        py = { name = "Python"; icon = ""; };
        go = { name = "Go"; icon = ""; };
        rs = { name = "Rust"; icon = ""; };
        sh = { name = "Shell"; icon = ""; };
        bash = { name = "Shell"; icon = ""; };
        zsh = { name = "Shell"; icon = ""; };
        fish = { name = "Fish"; icon = "󰈺"; };
        html = { name = "HTML"; icon = ""; };
        css = { name = "CSS"; icon = ""; };
        scss = { name = "SCSS"; icon = ""; };
        vue = { name = "Vue"; icon = ""; };
        svelte = { name = "Svelte"; icon = ""; };
        md = { name = "Markdown"; icon = ""; };
      };

      fallbackLanguage = {
        name = "Text";
        icon = "󰈙";
      };

      shellIcons = {
        fish = "󰈺";
        zsh = "";
        bash = "";
      };

      projectRootPatterns = [
        ".git"
        "flake.nix"
        "package.json"
        "Cargo.toml"
        "go.mod"
        "pyproject.toml"
      ];

      scannedFileLimit = 1500;

      # Copilot is a completion source, not a language server.
      ignoredLspClients = [
        "copilot"
        "copilot-language-server"
        "GitHub Copilot"
      ];

      noLspText = "No LSP";
      clockFormat = "%H:%M";
      lastStatus = 3;

      git = {
        background = "bg1";

        repositoryIcon = "";
        repositoryColour = "yellow";

        branchIcon = "";
        branchColour = "fg1";
        dirtyColour = "orange";
        noRepositoryText = "no repo";

        diffCounters = {
          added = { prefix = "+"; colour = "green"; };
          changed = { prefix = "~"; colour = "yellow"; };
          removed = { prefix = "-"; colour = "red"; };
        };

        modifiedIcon = "󰃭";
        modifiedColour = "gray";
        unsavedText = "unsaved";
        justNowText = "now";

        updateEvents = [ "BufEnter" "BufWritePost" "CursorHold" "FocusGained" "User" ];

        actions = {
          branches = { label = "Switch branch"; picker = "git_branches"; };
          changed = { label = "Changed files"; picker = "git_status"; };
          commits = { label = "Commits"; picker = "git_commits"; };
          fileCommits = { label = "Commits for this file"; picker = "git_bcommits"; };
          stashes = { label = "Stashes"; picker = "git_stash"; };
        };
      };
    };

    # ---- FILE EXPLORER ---- #
    explorer = {
      enable = true;

      position = "left";
      width = 36;
      openOnStart = true;

      followCurrentFile = true;
      showFilteredItems = true;
      showDotfiles = true;
      showGitIgnored = true;

      gitStatus = true;
      gitStatusAsync = true;
      refreshOnFocus = true;

      colourNamesByGitStatus = true;

      # The file's age is shown in the statusline instead, so names keep
      # the full width.
      showLastModified = false;

      # Compact labels that do not depend on the font.
      gitSymbols = {
        added = "+";
        conflict = "!";
        deleted = "-";
        ignored = "·";
        modified = "~";
        renamed = ">";
        staged = "+";
        unstaged = "~";
        untracked = "?";
      };

      gitSymbolAlignment = "right";

      palette = {
        green = "#b8bb26";
        aquaGreen = "#8ec07c";
        yellow = "#fabd2f";
        aqua = "#83a598";
        red = "#fb4934";
        orange = "#fe8019";
        gray = "#665c54";
      };

      # green = new, yellow = modified, red = deleted.
      gitHighlights = {
        NeoTreeGitAdded = { fg = "green"; };
        NeoTreeGitUntracked = { fg = "green"; };
        NeoTreeGitStaged = { fg = "aquaGreen"; };
        NeoTreeGitModified = { fg = "yellow"; };
        NeoTreeGitUnstaged = { fg = "yellow"; };
        NeoTreeGitRenamed = { fg = "aqua"; };
        NeoTreeGitDeleted = { fg = "red"; };
        NeoTreeGitConflict = { fg = "orange"; bold = true; };
        NeoTreeGitIgnored = { fg = "gray"; };
      };
    };

    # ---- PROJECTS ---- #
    projects = {
      enable = true;

      sessionDirectory = "dirsession";

      # Directories holding several projects.
      dev = [
        "~/.config"
        "~/Developer"
        "~/Projects"
      ];

      # Always listed, however recently they were opened.
      projects = [
        "~/.config/nix/nix-config"
      ];

      patterns = [
        ".git"
        "flake.nix"
        "package.json"
        "Cargo.toml"
        "go.mod"
        "pyproject.toml"
      ];

      recent = true;
    };

    # ---- COMPLETION ---- #
    completion = {
      enable = true;

      # Preview the selected completion inline.
      ghostText = true;

      copilot = {
        enable = true;

        autoTrigger = true;
        hideDuringCompletion = false;

        acceptKey = "<Tab>";
        previousKey = "<S-Tab>";
      };
    };

    # ---- NOTIFICATIONS ---- #
    notify = {
      enable = true;

      # 0 keeps a notification until it is dismissed.
      timeout = 3000;
      refresh = 50;

      # Fractions are a share of the editor, whole numbers are cells.
      width = { min = 40; max = 0.4; };
      height = { min = 1; max = 0.6; };

      margin = { top = 0; right = 1; bottom = 0; };

      padding = true;
      gap = 1;

      style = "compact";
      topDown = true;
      sort = [ "level" "added" ];
      level = "TRACE";

      dateFormat = "%R";
      moreFormat = " ↓ %d lines ";
      keepWhileTyping = true;

      icons = {
        error = " ";
        warn = " ";
        info = " ";
        debug = " ";
        trace = " ";
      };

      border = "rounded";
      blend = 0;
      wrap = true;

      historyTitle = " Notifications ";
      historyTitlePosition = "center";

      palette = {
        bg1 = "#3c3836";
        fg1 = "#ebdbb2";
        gray = "#a89984";
        yellow = "#fabd2f";
        aqua = "#83a598";
        green = "#b8bb26";
        red = "#fb4934";
        purple = "#d3869b";
      };

      levelColours = {
        Error = "red";
        Warn = "yellow";
        Info = "aqua";
        Debug = "gray";
        Trace = "purple";
      };

      backgroundColour = "bg1";
      historyForeground = "fg1";
    };

    # ---- DROPBAR ---- #
    # Clickable breadcrumb navigation.
    dropbar = {
      enable = true;

      dependencies = [ "nvim-tree/nvim-web-devicons" ];

      icons.enable = true;

      separator = "  ";
      extends = "…";

      padding = {
        left = 1;
        right = 1;
      };

      palette = {
        bg0 = "#282828";
        bg1 = "#3c3836";
        fg1 = "#ebdbb2";
        gray = "#a89984";
        yellow = "#fabd2f";
        orange = "#fe8019";
        aqua = "#83a598";
        green = "#b8bb26";
      };

      highlights = {
        WinBar = { fg = "fg1"; bg = "bg0"; };
        WinBarNC = { fg = "gray"; bg = "bg0"; };

        DropBarIconUISeparator = { fg = "yellow"; bg = "bg0"; };
        DropBarIconUISeparatorMenu = { fg = "orange"; bg = "bg0"; };

        DropBarIconKindDefault = { fg = "aqua"; bg = "bg0"; };
        DropBarIconKindFolder = { fg = "yellow"; bg = "bg0"; };
        DropBarIconKindFile = { fg = "aqua"; bg = "bg0"; };

        DropBarKindDefault = { fg = "fg1"; bg = "bg0"; };
        DropBarKindFolder = { fg = "yellow"; bg = "bg0"; bold = true; };
        DropBarKindFile = { fg = "aqua"; bg = "bg0"; bold = true; };

        DropBarCurrentContext = { fg = "bg0"; bg = "yellow"; bold = true; };
        DropBarCurrentContextIcon = { fg = "bg0"; bg = "yellow"; bold = true; };
        DropBarCurrentContextName = { fg = "bg0"; bg = "yellow"; bold = true; };
        DropBarHover = { fg = "bg0"; bg = "aqua"; };

        DropBarMenuNormalFloat = { fg = "fg1"; bg = "bg1"; };
        DropBarMenuFloatBorder = { fg = "yellow"; bg = "bg1"; };
        DropBarMenuCurrentContext = { fg = "bg0"; bg = "yellow"; bold = true; };
        DropBarMenuHoverEntry = { fg = "bg0"; bg = "aqua"; };
      };

      kindGroups = {
        callable = {
          kinds = [ "Function" "Method" "Constructor" "Class" "Interface" ];
          fg = "green";
          bg = "bg0";
          bold = true;
        };

        values = {
          kinds = [ "Variable" "Field" "Property" "Constant" ];
          fg = "aqua";
          bg = "bg0";
        };

        modules = {
          kinds = [ "Module" "Namespace" "Package" ];
          fg = "orange";
          bg = "bg0";
          bold = true;
        };
      };
    };

    # ---- GITSIGNS ---- #
    git = {
      enable = true;

      # Keep a permanent gutter marker and tint changed lines, which is
      # stronger than the AstroNvim default.
      signColumn = true;
      lineHighlight = true;
      attachToUntracked = true;

      watchGitDirectory = true;
      followFiles = true;

      signs = {
        add = "▎";
        change = "▎";
        changedelete = "~";
        delete = "▁";
        topdelete = "▔";
        untracked = "┆";
      };

      lineBlame = {
        enable = true;
        position = "eol";
        delay = 400;
        ignoreWhitespace = false;
        formatter = "  <author>, <author_time:%R> — <summary>";
      };

      # Backgrounds that keep the line highlights visible without losing
      # the colorscheme's contrast.
      lineHighlightColours = {
        GitSignsAddLn = "#3a421a";
        GitSignsChangeLn = "#4a3b16";
        GitSignsChangedeleteLn = "#4a2b1c";
        GitSignsDeleteLn = "#4a1f1d";
        GitSignsTopdeleteLn = "#4a1f1d";
        GitSignsUntrackedLn = "#3a421a";
      };
    };

    # ---- TELESCOPE ---- #
    telescope = {
      enable = true;

      layoutStrategy = "horizontal";
      sortingStrategy = "ascending";

      promptPosition = "top";
      previewWidth = 0.55;
      width = 0.9;
      height = 0.85;
    };
  };
}
