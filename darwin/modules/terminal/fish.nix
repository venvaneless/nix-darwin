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
  # ENVIRONMENT
  # -------------------------------------------- #
  # Paths
  home = {
	    sessionPath = [
	    	# homebrew PATHS
	      "/opt/homebrew/bin"
	      "/opt/homebrew/sbin"
	      "${config.home.homeDirectory}/.local/bin"

	      # Docker PATH
	      "/Applications/Programming/Docker.app/Contents/Resources/bin"
	    ];

			  # Environment
					sessionVariables = {
						COLORTERM = "truecolor";
						MICRO_TRUECOLOR = "1";
					};
	  };

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
    ./modules/atuin.nix
    ./modules/bat.nix
    ./modules/bottom.nix
    ./modules/delta.nix
    ./modules/eza.nix
    # ./modules/fastfetch.nix
    ./modules/fzf.nix
    # ./modules/lazygit.nix
    # ./modules/micro.nix
    # ./modules/ranger.nix
    # ./modules/ripgrep.nix
    # ./modules/starship.nix
    # ./modules/zoxide.nix
  ];
}