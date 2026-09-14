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
    # Bat settings and the theme selected in bat.nix
    ./bat/bat.nix

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

    # Television channels and the theme selected in television/default.nix
    ./television

    ./tmux.nix
    # Yazi settings and plugins
    ./yazi
    ./zoxide.nix
  ];

  config = {
    # ------------------------------------------------------------
    # ------ MICRO SETTINGS ------ #
    # All values a user may reasonably change stay here. The option module
    # owns platform selection, validation, JSON rendering, and theme files.

    cli.micro = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      trueColor = true;

      themes.default = "gruvbox";

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

    cli.gh = {
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
    # ------ ATUIN SETTINGS ------ #
    # Atuin implementation, platform selection, and theme files live in
    # options/cli/atuin/default.nix. Exactly one theme may be enabled at a time.

    cli.atuin = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      themes = {
        catppuccinMochaMauve.enable = false;
        gruvboxDark.enable = true;
      };

      settings = {
        enter_accept = true;

        sync = {
          # Keep Atuin sync-v2 records enabled for existing history data.
          records = true;
        };
      };

      fish = {
        # Prevent Atuin from automatically taking over keybindings.
        preventAutomaticKeybindings = true;

        # Bind Ctrl-R to Atuin search.
        searchBinding = "\\cr";
      };
    };
  };
}
