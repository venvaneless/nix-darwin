	# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh.nix
	#
	# MODULAR ZSH CONFIGURATION (HOME MANAGER)
	# ============================================================
	# - Manages Zsh through Home Manager
	# - ZDOTDIR = ~/dotfiles/zsh
	# - Aliases + helper functions live here
	# - Completion, compinit, fzf, autosuggestions, syntax highlighting,
	#   history search, asdf, forgit, fzf-tab all come from ./plugins/*.nix
	# ============================================================
	
	{ config, lib, pkgs, ... }:
	
	{
	  programs.zsh = {
	    enable = true;
			
			# Force Home Manager to create .zshrc and .zshenv
			dotDir = "${config.home.homeDirectory}/dotfiles/zsh";
						
			# zshenv = "${config.home.homeDirectory}/dotfiles/zsh/.zshenv";  
	
	    # DO NOT put completion, compinit, zstyle, or external completions here.
	    # Those belong in plugins/completion.nix now.
	
	    # Only keep your functions + aliases here.
	    initContent = ''
	      # --- Nix maintenance helpers ---
	      ddg() { sudo -H nix-env --delete-generations "$@" --profile /nix/var/nix/profiles/system; }
	
	      ndg() { sudo nix-collect-garbage --delete-older-than "$1"d; }
	
	      ndgcg30() {
	        echo "🧹 Deleting old generations (+5) and collecting garbage older than 30 days..."
	        sudo -H nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system
	        sudo nix-collect-garbage --delete-older-than 30d
	        echo "✅ Cleanup complete."
	      }
	    '';
	
	    # ----- Shell aliases -----
	    shellAliases = {
	      # Nix-darwin
	      drb  = "sudo -E -s darwin-rebuild build --flake /Users/ven/dotfiles/nix#macbook";
	      drs  = "sudo -E -s darwin-rebuild switch --flake /Users/ven/dotfiles/nix#macbook";
	      drn  = "sudo -E -s darwin-rebuild dry-run --flake /Users/ven/dotfiles/nix#macbook";
	
	      # Home Manager
	      drh  = "home-manager switch --flake /Users/ven/dotfiles/nix#ven";
	      drhb = "home-manager build --flake /Users/ven/dotfiles/nix#ven";
	
	      # Generations
	      drg  = "sudo -H nix-env --list-generations --profile /nix/var/nix/profiles/system";
	
	      # Git scripts
	      gsn = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/nix-repo.sh";
	      gsd = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/dotfiles-repo.sh";
	    };
	  };
	
	  # Correct session PATH for Homebrew + Docker CLI
	  home.sessionPath = [
	    "/opt/homebrew/bin"
	    "/opt/homebrew/sbin"
	    "${config.home.homeDirectory}/.local/bin"
	    "/Applications/Programming/Docker.app/Contents/Resources/bin"
	  ];
	
	  # --- Modular plugin imports ----
	  imports = [
	    ./plugins/completion.nix
	    ./plugins/fzf.nix
	    ./plugins/autosuggestions.nix
	    ./plugins/syntax-highlighting.nix
	    ./plugins/history.nix
			./plugins/forgit.nix
	
	    # keep commented modules if you want — they won’t break anything
	    # ./plugins/asdf.nix
	    # ./plugins/starship.nix
	    # ./plugins/thefuck.nix
	  ];
	}
