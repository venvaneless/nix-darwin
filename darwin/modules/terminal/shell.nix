# /Users/ven/dotfiles/nix/darwin/modules/terminal/shell.nix

{ config, pkgs, ... }:

{
  # ============================================================
  # System-level environment for Nix + Zsh
  # ============================================================

  environment.systemPath = [
    pkgs.nix
  ];

  environment.variables = {
    NIX_PROFILES =
      "/nix/var/nix/profiles/default /run/current-system/sw /Users/ven/.nix-profile";
  };

  # EARLY-GLOBAL PATH FIX (CORRECT M1 HOME-BREW PREFIX FIRST)
  environment.etc."zshenv.local".text = ''
    unset __ETC_PROFILE_NIX_SOURCED

    # Load nix-daemon environment
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    # Correct PATH order for Apple Silicon
    export PATH="/opt/homebrew/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"

    # ZDOTDIR for modular Zsh setup
    export ZDOTDIR="$HOME/dotfiles/zsh"
  '';

  programs.zsh.enable = true;
}
