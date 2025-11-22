# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh.nix
#
# ZSH CONFIGURATION
# ============================================================
# Home-Manager-managed Zsh:
# - Uses dotDir = ~/dotfiles/zsh
# - Adds Homebrew + Docker CLI to PATH via home.sessionPath
# - Loads conf.d/*.zsh from $ZDOTDIR
# - Sets up completion, compinit, menu selection
# - Provides Nix maintenance helpers + system aliases
# - Imports modular feature modules from ./zsh/*.nix
# ============================================================

{ config, lib, pkgs, ... }:

{
  # ----- Zsh program (Home Manager) -----
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Put all runtime Zsh files under ~/dotfiles/zsh
    dotDir = "${config.home.homeDirectory}/dotfiles/zsh";

    # Built-in HM integration for extras
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    historySubstringSearch.enable = true;

    # Make absolutely sure ZDOTDIR is correct early
    initExtraBeforeCompInit = ''
      # Ensure ZDOTDIR is set for this session
      export ZDOTDIR="$HOME/dotfiles/zsh"
    '';

    initExtra = ''
      # --- Load modular conf.d snippets (runtime-level) ---
      # This lets you drop custom *.zsh files into $ZDOTDIR/conf.d
      # without changing Nix.
      if [ -d "$ZDOTDIR/conf.d" ]; then
        for file in "$ZDOTDIR"/conf.d/*.zsh; do
          [ -f "$file" ] && source "$file"
        done
      fi

      # --- Fix insecure completion dirs ---
      # Avoid annoying compaudit prompts and still get completion.
      ZSH_DISABLE_COMPFIX=true
      autoload -Uz compinit
      compinit -u

      # Enable interactive completion menu (after compinit)
      zstyle ':completion:*' menu select

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
      # Nix-darwin & Home Manager
      drb  = "sudo -E -s darwin-rebuild build --flake /Users/ven/dotfiles/nix#macbook";
      drs  = "sudo -E -s darwin-rebuild switch --flake /Users/ven/dotfiles/nix#macbook";
      drn  = "sudo -E -s darwin-rebuild dry-run --flake /Users/ven/dotfiles/nix#macbook";
      drh  = "home-manager switch --flake /Users/ven/dotfiles/nix#ven";
      drhb = "home-manager build --flake /Users/ven/dotfiles/nix#ven";
      drg  = "sudo -H nix-env --list-generations --profile /nix/var/nix/profiles/system";

      # Git helper scripts
      gsn = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/nix-repo.sh";
      gsd = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/dotfiles-repo.sh";
    };
  };

  # ----- FZF integration -----
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # ----- PATH: Homebrew + Docker CLI + local bin -----
  # This is the *correct* place to put PATH tweaks for the user.
  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "${config.home.homeDirectory}/.local/bin"
    "/Applications/Programming/Docker.app/Contents/Resources/bin"
  ];

  # ----- Modular Zsh feature modules (Nix-level) -----
  # Put feature modules under ./zsh/ and toggle them here.
  imports = [
    ./plugins/fzf.nix
    ./plugins/syntax-highlighting.nix
    ./plugins/autosuggestions.nix
    ./plugins/history.nix
    ./plugins/thefuck.nix
    ./plugins/starship.nix
    ./plugins/asdf.nix
  ];
}
