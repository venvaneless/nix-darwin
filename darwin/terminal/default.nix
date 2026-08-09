# darwin/terminal/default.nix
#
# FISH CONFIGURATION
# =====================================================================
# - Manages Fish through nix-darwin
# - Aliases live in ./plugins/aliases
# - Larger Fish integrations live in ./plugins/modules
# - Small built-in Fish behavior stays here:
#   completions, history name, autosuggestions, syntax highlighting
# =====================================================================

{ config, pkgs, ... }:

{
  # Enable fish shell
  programs.fish = {
    enable = true;

    # -------------------------------------------- #
    # FISH SETTINGS
    # -------------------------------------------- #

    # ---- PLUGINS ---- #
    plugins = [
      {
        # Plugin that allows for automatic pairing of brackets, quotes, etc.
        name = "autopair.fish";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "autopair.fish";
          rev = "main";
          hash = "sha256-qt3t1iKRRNuiLWiVoiAYOu+9E7jsyECyIqZJ/oRIT1A=";
        };
      }
    ];

    # ---- CONFIGURATION ---- #
    shellInit = ''
        # Hide default greeting
        set fish_greeting

        # Use a named Fish history file
        set -g fish_history ven

      # Direnv integration
      direnv hook fish | source
    '';

    interactiveShellInit = ''
      # Completions
      fish_default_key_bindings

      # Autosuggestions
      set -g fish_autosuggestion_enabled 1

      # Common paths
        set -gx ICLOUD_MOBILE "$HOME/Library/Mobile Documents"
    '';
  };

  # ---- COMPLETIONS ---- #
  xdg.configFile."fish/completions/docker.fish".source =
    "${pkgs.docker_29}/share/fish/vendor_completions.d/docker.fish";

  # ---- THEMES ---- #
  # Set the default Fish theme
  terminal.fish.theme = "gruvbox";

  # ---- ENVIRONMENT ---- #
  home = {
    sessionPath = [
      # homebrew PATHS
      # "/opt/homebrew/bin"
      # "/opt/homebrew/sbin"
      "${config.home.homeDirectory}/.local/bin"

      # Docker PATH
      "/Applications/Programming/Docker.app/Contents/Resources/bin"
    ];

    # ---- ENVIRONMENT VARIABLES ---- #
    sessionVariables = {
      # COLORTERM = "truecolor";
      MICRO_TRUECOLOR = "1";

      ICLOUD = "$HOME/iCloudDocs";
      CHATGPT_APP = "/Applications/ChatGPT.app";
    };
  };

  # -------------------------------------------- #
  # MODULES
  # -------------------------------------------- #
  imports = [
    # ---- Aliases ---- #

    # Fish aliases
    ./aliases/shell-aliases.nix

    # Commands and functions
    ./commands

    # Nix aliases and functions
    ./aliases/gc-aliases.nix
    ./aliases/git-aliases.nix
    ./aliases/nix-aliases.nix

    # ---- Fish themes ---- #
    ./fish-themes.nix

  ];
}
