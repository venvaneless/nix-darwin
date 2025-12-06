# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/base.nix
# 
{ config, pkgs, lib, inputs, ... }:

{
  # --- Core system identity ---
  networking.hostName = "Vens-MacBook-Pro";

  # Tell nix‑darwin to manage /etc/nix/nix.conf for us
  nix.enable = true;

  # --- Enable new Nix CLI and flakes, and configure caches ---
  nix.settings = {
    # enable the new CLI and flake support
    experimental-features = [ "nix-command" "flakes" ];

    # build users group for multi-user Nix
    build-users-group = "nixbld";

    # Move Nix directories (profiles, channels, defexpr) to the XDG base directories.
    # This removes ~/.nix-profile and ~/.nix-defexpr in favour of $XDG_STATE_HOME/nix.
    use-xdg-base-directories = true;

    # Use only the official cache for now; this removes the bad key permanently.
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # When using XDG base directories, Nix will default to $XDG_STATE_HOME/nix for
  # profiles and expressions.  To keep **all** of these files under
  # ~/.config/nix, override XDG variables accordingly.  These variables
  # affect all applications, so consider this carefully.
  environment.variables = {
    XDG_STATE_HOME = "$HOME/.config";
    XDG_DATA_HOME  = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.config";
  };

  # --- System state version (Darwin revision) ---
  system.stateVersion = 6;

  # --- Global system packages ---
  environment.systemPackages = with pkgs; [
    inputs.darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild
    # Newest bash
    bashInteractive
    git-crypt
    home-manager
    nssTools
    # Nix linter
    nixd
    nil
    # YAML CLI 
    yq-go
  ];
}
