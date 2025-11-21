# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh.nix
#
# ZSH CONFIGURATION
# ============================================================
# Enables Zsh, sets up PATH and environment,
# loads conf.d snippets, and defines rebuild + maintenance shortcuts.
# ============================================================

{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    dotDir = "${config.home.homeDirectory}/dotfiles/zsh";

    initContent = ''
      # Ensure Nix paths visible
      # (PATH is already set correctly in zshenv.local — don't override here)
      if [[ ":$PATH:" != *":/run/current-system/sw/bin:"* ]]; then
        :
      fi

      # Load nix-daemon environment
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi

      # Load modular conf.d snippets
      if [ -d "$ZDOTDIR/conf.d" ]; then
        for file in "$ZDOTDIR"/conf.d/*.zsh; do
          source "$file"
        done
      fi

      # --- Fix insecure completion dirs ---
      ZSH_DISABLE_COMPFIX=true
      autoload -Uz compinit
      compinit -u

      # Enable interactive completion menu (must come *after* compinit)
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

    shellAliases = {
      drb  = "sudo -E -s darwin-rebuild build --flake /Users/ven/dotfiles/nix#macbook";
      drs  = "sudo -E -s darwin-rebuild switch --flake /Users/ven/dotfiles/nix#macbook";
      drn  = "sudo -E -s darwin-rebuild dry-run --flake /Users/ven/dotfiles/nix#macbook";
      drh  = "home-manager switch --flake /Users/ven/dotfiles/nix#ven";
      drhb = "home-manager build --flake /Users/ven/dotfiles/nix#ven";
      drg  = "sudo -H nix-env --list-generations --profile /nix/var/nix/profiles/system";
      gsn = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/nix-repo.sh";
      gsd = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/dotfiles-repo.sh";
      
      # TEST SCRIPTS
      gsnt = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/nix-repo-test.sh";
      gsdt = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/dotfiles-repo-test.sh";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Correct PATH order for Apple Silicon
  home.sessionPath = [
    "/opt/homebrew/bin"
    "$HOME/.local/bin"
  ];

  # Automatically import submodules under ./zsh/
  imports = let
    zshModules =
      lib.attrValues (lib.mapAttrs
        (name: _: ./zsh/${name})
        (lib.filterAttrs
          (name: type:
            type == "regular" && lib.hasSuffix ".nix" name)
          (builtins.readDir ./zsh)));
  in zshModules;
}
