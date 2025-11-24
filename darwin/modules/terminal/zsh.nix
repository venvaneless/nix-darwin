# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh.nix
#
# ZSH CONFIGURATION
# ============================================================
# - Manages Zsh through Home Manager
# - ZDOTDIR = ~/dotfiles/zsh
# - Aliases + helper functions live here
# - Completion, compinit, fzf, autosuggestions, syntax highlighting,
#   history search, asdf, forgit, fzf-tab all come from ./plugins/*.nix
# ============================================================

{ config, lib, pkgs, ... }:

# Enanble zsh shell
{
  programs.zsh = {
    enable = true;

    # Keeps zshrc owned by HM here
    dotDir = "${config.home.homeDirectory}/dotfiles/zsh";

    
    # ----------------------------------------------------------------- #
    # 
    # 
    # Only keep functions + aliases here
    initContent = ''
    
      # --- Nix maintenance helpers ---
      # Delete old generations
      ddg() { sudo -H nix-env --delete-generations "$@" --profile /nix/var/nix/profiles/system; }

      # Garbage collector
      ndg() { sudo nix-collect-garbage --delete-older-than "$1"d; }

      # Deleting both old generations and garbage
      ndgcg30() {
        echo "Deleting old generations (+5) and collecting garbage older than 30 days..."
        sudo -H nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system
        sudo nix-collect-garbage --delete-older-than 30d
        echo "Cleanup complete."
      }
    '';

    # ----------------------------------------------------------------- #
    # 
    shellAliases = {

    	# --- Nix darwin
      drb  = "sudo -H -s darwin-rebuild build --flake /Users/ven/dotfiles/nix#macbook";
      drs  = "sudo -H -s darwin-rebuild switch --flake /Users/ven/dotfiles/nix#macbook";
      drn  = "sudo -H -s darwin-rebuild check --flake /Users/ven/dotfiles/nix#macbook";

      # --- Home Manager


      # --- Deletes old gens
      drg  = "sudo -H nix-env --list-generations --profile /nix/var/nix/profiles/system";

      # --- Git
      gsn = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/nix-repo.sh";
      gsd = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/dotfiles-repo.sh";
    };
  };

  
  # ----------------------------------------------------------------- #
  # 
  # ----- HOME-LEVEL VARIABLES -----
  # 
  # --- Correct session PATHS
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
  # 
  # ----- Plugin imports -----
  imports = [
    ./plugins/completion.nix
    ./plugins/fzf.nix
    ./plugins/autosuggestions.nix
    ./plugins/syntax-highlighting.nix
    ./plugins/history.nix

    # Optional
    # ./plugins/asdf.nix
    # ./plugins/starship.nix
    # ./plugins/thefuck.nix
  ];
}
