# shared/terminal/cli-tuis/default.nix
#
# CLI AND TUI TOOLS
# =====================================================================
# - Imports all command-line and terminal UI tool modules
# - Each tool owns its own macOS and Linux enable toggles
# - Imported by each host home module
# =====================================================================

{ ... }:
{
  imports = [
    # Atuin settings and its themes
    ./atuin

    # Bat settings and its themes
    ./bat

    # Btop settings and the theme selected in btop.nix
    ./btop/btop.nix

    # Delta settings and the theme selected in delta.nix
    ./delta/delta.nix

    # Eza settings; its themes are imported from eza.nix
    ./eza/eza.nix

    ./fastfetch/fastfetch.nix

    # Fd settings, its ignore file, and the theme selected in fd.nix
    ./fd/fd.nix

    ./fzf/fzf.nix

    ./pet.nix
    ./ripgrep.nix
    ./starship.nix

    ./tmux.nix
    # Yazi settings and plugins
    ./yazi
    ./zoxide.nix
  ];

  config = {
    # ------------------------------------------------------------
    # ------ NAVI SETTINGS ------ #
    # Navi's Home Manager module installs the command and wires its widget
    # into Fish without a separate package declaration.
  programs = {
    navi = {
      enable = true;
      enableFishIntegration = true;
    };
    jujutsu = {
      enable = true;
      settings = {
        user = "ven";
        email = "ven@example.com";
        name = "Ven";
        editor = "micro";
        color = "orange";
      };
    };
  };





    # ------------------------------------------------------------
    # ------ MICRO SETTINGS ------ #
    # All values a user may reasonably change stay here. The option module
    # owns platform selection, validation, JSON rendering, and theme files.

    home.shared.cli.micro = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      trueColor = true;

      themes = {
        # Select one enabled theme for Micro's settings.json.
        selected = "gruvbox";

        # Theme modules are individually toggleable through this registry.
        gruvbox.enable = true;
      };

      settings = {
        clipboard = "external";
        savecursor = true;
        saveundo = true;
        scrollbar = true;
        softwrap = false;
        tabsize = 4;
        tabstospaces = true;
      };

      bindings = {
        "Alt-/" = "lua:comment.comment";
        CtrlUnderscore = "lua:comment.comment";
        CtrlC = "Copy";
        CtrlW = "Paste";
        CtrlX = "Cut";
        CtrlA = "SelectAll";
      };
    };

    # ------------------------------------------------------------
    # ------ GITHUB CLI SETTINGS ------ #
    # GitHub CLI implementation and platform selection live in
    # options/cli/gh.nix. OAuth credentials remain user-owned in hosts.yml.

    home.shared.cli.gh = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      gitCredentialHelper = {
        enable = true;
        hosts = [
          "https://github.com"
          "https://gist.github.com"
        ];
      };

      settings = {
        # Protocol used for clone, fork, and remote operations.
        git_protocol = "https";

        # Empty values keep gh deferring to the environment.
        editor = "";
        pager = "";
        browser = "";
        http_unix_socket = "";

        # Interactive prompting, in the terminal rather than an editor.
        prompt = "enabled";
        prefer_editor_prompt = "disabled";

        # Animated progress indicator.
        spinner = "enabled";

        # Accessibility and colour behaviour left at gh's defaults.
        # Set color_labels to "enabled" for truecolor issue labels.
        color_labels = "enabled";
        accessible_colors = "disabled";
        accessible_prompter = "disabled";

        # ---- ALIASES ---- #
        aliases = {
          # --- gh co -> gh pr checkout
          ## Check out the branch behind a pull request.
          co = "pr checkout";
        };
      };
    };
    # ------------------------------------------------------------
    # ------ TELEVISION SETTINGS ------ #
    # Television logic, rendering, and channel implementation live in
    # options/cli/television. Channel actions use commands from PATH.

    home.shared.cli.television = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      # Theme written to [ui]: default or gruvbox.
      uiTheme = "gruvbox";

      # [ui.preview_panel]
      previewPanel = {
        size = 55;
        scrollbar = true;
      };

      # [ui.help_panel]
      helpPanel = {
        hidden = true;
      };

      # [ui.remote_control]
      remoteControl = {
        showChannelDescriptions = true;
        sortAlphabetically = true;
      };

      search.excludedDirectories = [ ".git" "result" "result-*" ".cache" ];

      actions = {
        default = "nvim";
        nvim.enable = true;
        zed.enable = true;
        copyAbsolutePath = true;
        copyRelativePath = true;
      };

      channels = {
        # Browse Nix files under the main configuration root.
        nix = {
          enable = true;
          fileGlobs = [ "*.nix" ];
        };

        # Search text inside Nix files.
        nixFiles = {
          enable = true;
          fileGlobs = [ "*.nix" ];
        };

        # Search common Nix declarations with ripgrep expressions.
        nixSymbols = {
          enable = true;
          patterns = [
            "environment\\.systemPackages"
            "home\\.packages"
            "imports[[:space:]]*="
            "programs\\."
            "services\\."
            "options\\."
            "config\\."
          ];
        };

        # Search Nix import declarations and relative module paths.
        nixImports = {
          enable = true;
          patterns = [
            "imports[[:space:]]*="
            "^[[:space:]]*\\.?\\.?/.*\\.nix"
            "(^|[[:space:](])(builtins\\.)?import[[:space:]]+\\(?\\.?\\.?/.*\\.nix"
          ];
        };

        # List recently modified Nix files, newest first.
        nixRecent = {
          enable = true;
          maxResults = 100;
        };

        # Browse tracked and untracked Git changes in the Nix repository.
        nixGit = {
          enable = true;
          includeUntracked = true;
        };

        # Browse Nix files only inside the darwin/ directory.
        nixDarwin = {
          enable = true;
          fileGlobs = [ "*.nix" ];
        };
      };
    };
  };
}
