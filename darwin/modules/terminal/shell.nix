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

  environment.etc."zshenv.local".text = ''
    unset __ETC_PROFILE_NIX_SOURCED
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"
    export ZDOTDIR="$HOME/dotfiles/zsh"
  '';

  programs.zsh.enable = true;
}
