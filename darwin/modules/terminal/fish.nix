# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/fish.nix
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
    # PLUGINS
    # -------------------------------------------- #
    plugins = [
      {
        name = "autopair.fish";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "autopair.fish";
          rev = "main";
          hash = "sha256-qt3t1iKRRNuiLWiVoiAYOu+9E7jsyECyIqZJ/oRIT1A=";
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

      # Common paths
        set -gx ICLOUD_MOBILE "$HOME/Library/Mobile Documents"
    '';
  };

  # -------------------------------------------- #
  # THEME
  # -------------------------------------------- #
  terminal.fish.theme = "gruvbox";

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
						# COLORTERM = "truecolor";
						MICRO_TRUECOLOR = "1";

						ICLOUD = "$HOME/iCloudDocs";
						CHATGPT_APP = "/Applications/ChatGPT Classic.app";
					};
	  };

  # -------------------------------------------- #
  # MODULES
  # -------------------------------------------- #
  imports = [
    # ---- Aliases ---- #
    ./aliases/shell-aliases.nix
    ./aliases/fish-functions.nix
		./aliases/gc-aliases.nix
		./aliases/git-aliases.nix
    ./aliases/nix-aliases.nix

    # ---- Fish themes ---- #
    ./fish-themes.nix

    # ---- Fish modules ---- #
    ./plugins/atuin.nix
    ./plugins/bat.nix
    ./plugins/bottom.nix
    ./plugins/delta.nix
    ./plugins/eza.nix
    ./plugins/fastfetch.nix
    ./plugins/fzf.nix
    ./plugins/lazygit.nix
    ./plugins/micro.nix
    ./plugins/mise.nix
    ./plugins/ripgrep.nix
    ./plugins/starship.nix
    ./plugins/zoxide.nix
  ];
}