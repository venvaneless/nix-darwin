# /Users/ven/dotfiles/nix/darwin/modules/terminal/shell.nix

{ config, pkgs, lib, ... }:

{
  # ============================================================
  # System-level environment for Nix + Zsh
  # ============================================================

  environment.systemPath = [
    pkgs.nix
  ];

  # Hard override PATH so nix-daemon.sh cannot reintroduce /usr/local/bin
  environment.variables = {
    NIX_PROFILES =
      "/nix/var/nix/profiles/default /run/current-system/sw /Users/ven/.nix-profile";

    PATH = lib.mkForce "/opt/homebrew/bin:/opt/homebrew/sbin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/Users/ven/.nix-profile/bin";
  };

  # EARLY-GLOBAL PATH FIX (correct Apple Silicon prefix)
  environment.etc."zshenv.local".text = ''
    unset __ETC_PROFILE_NIX_SOURCED

    # Load nix-daemon environment
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    # Ensure PATH starts with ARM Homebrew (do NOT append $PATH)
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/Users/ven/.nix-profile/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    # Modular zsh directory
    export ZDOTDIR="$HOME/dotfiles/zsh"
  '';

  programs.zsh.enable = true;
}
