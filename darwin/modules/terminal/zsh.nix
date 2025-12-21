	# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/zsh.nix
	#
	# ZSH CONFIGURATION
	# ============================================================
	# - Manages Zsh through Home Manager
	# - ZDOTDIR = ~/dotfiles/zsh
	# - Aliases live in ./aliases
	# - Completion, compinit, fzf, autosuggestions, syntax highlighting,
	#   history search, asdf, forgit, fzf-tab all come from ./plugins/*.nix
	# ============================================================
	
	{ config, lib, pkgs, ... }:
	
	# Enanble zsh shell
	{
	  programs.zsh = {
	    enable = true;
		
	  # Keeps zshrc owned by HM here
		dotDir = "${config.home.homeDirectory}/ven-dots/zsh";
  };
	 
	  # ----------------------------------------------------------------- #
	  # HOME-LEVEL VARIABLES
	  # ----------------------------------------------------------------- #
		# 
	  # --- Correct session PATHS ---- #
	  home = {
	    sessionPath = [
	    	# homebrew PATHS
	      "/opt/homebrew/bin"
	      "/opt/homebrew/sbin"
	      "${config.home.homeDirectory}/.local/bin"
	      
	      # Docker PATH
	      "/Applications/Programming/Docker.app/Contents/Resources/bin"
	    ];
	  };
	
	  
	  # ----------------------------------------------------------------- #
		# PLUGINS
		# ----------------------------------------------------------------- #
	  imports = [
			./aliases/nix-aliases.nix
			./aliases/gc-aliases.nix
			./aliases/git-aliases.nix
			./aliases/test-aliases.nix
  
    	./plugins/asdf.nix
    	./plugins/autosuggestions.nix
	    ./plugins/completion.nix
			./plugins/payf.nix
	    ./plugins/fzf.nix
	    ./plugins/history.nix
			./plugins/mcfly.nix
			./plugins/mise.nix
			./plugins/starship.nix
	    ./plugins/syntax-highlighting.nix
	  ];
	}

