# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/fish.nix
#
# FISH CONFIGURATION
# =====================================================================
# - Manages Fish through nix-darwin
# - Aliases live in ./modules/aliases
# - Larger Fish integrations live in ./modules/modules
# - Small built-in Fish behavior stays here:
#   completions, history name, autosuggestions, syntax highlighting
# =====================================================================

{ config, pkgs, ... }:

{
  # Enable fish shell
  programs.fish = {
    enable = true;

    # -------------------------------------------- #
    # PLUGINS
    # -------------------------------------------- #
    plugins = [
      {
        name = "autopair.fish";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "autopair.fish";
          rev = "main";
          hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        };
      }

      # Theme
      {
        name = "rose-pine";
        src = pkgs.fetchFromGitHub {
          owner = "rose-pine";
          repo = "fish";
          rev = "main";
          hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
        };
      }
    ];

    # -------------------------------------------- #
    # CONFIG
    # -------------------------------------------- #
    shellInit = ''
      # Hide default greeting
      set fish_greeting

      # Use a named Fish history file
      set -g fish_history ven
    '';

    interactiveShellInit = ''
      # Completions
      fish_default_key_bindings

      # Autosuggestions
      set -g fish_autosuggestion_enabled 1
    '';
  };

  # -------------------------------------------- #
  # SHELL REGISTRATION
  # -------------------------------------------- #
  environment.shells = [
    pkgs.fish
  ];

  users.users.ven.shell = pkgs.fish;

  # Environment
  environment.variables = {
    COLORTERM = "truecolor";
    MICRO_TRUECOLOR = "1";
  };

  # -------------------------------------------- #
  # PATHS
  # -------------------------------------------- #
  environment.systemPath = [
    # Homebrew paths
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"

    # User-local binaries
    "/Users/ven/.local/bin"

    # Docker path
    "/Applications/Programming/Docker.app/Contents/Resources/bin"
  ];

  # -------------------------------------------- #
  # MODULES
  # -------------------------------------------- #
  imports = [
    # ---- Aliases ---- #
    ./aliases/nix-aliases.nix
		./aliases/gc-aliases.nix
		./aliases/git-aliases.nix
		./aliases/shell-aliases.nix

    # ---- Fish modules ---- #
    ./modules/modules/atuin.nix
    ./modules/modules/bat.nix
    ./modules/modules/bottom.nix
    ./modules/modules/delta.nix
    ./modules/modules/eza.nix
    ./modules/modules/fastfetch.nix
    ./modules/modules/fzf.nix
    ./modules/modules/lazygit.nix
    ./modules/modules/micro.nix
    ./modules/modules/ranger.nix
    ./modules/modules/ripgrep.nix
    ./modules/modules/starship.nix
    ./modules/modules/zoxide.nix
  ];
}