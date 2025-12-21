# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/base.nix
#
{ config, pkgs, lib, inputs, ... }:

{
  # ------------------------------------------------------------
  # SYSTEM MODULE IMPORTS
  # Dock, Finder, fonts, trackpad
  # ------------------------------------------------------------
  imports = [
    ./system-options.nix
  ];

  # ------------------------------------------------------------
  # SYSTEM IDENTITY
  # ------------------------------------------------------------
  networking.hostName = "Vens-MacBook-Pro";

  # ------------------------------------------------------------
  # NIX SETTINGS
  # ------------------------------------------------------------
  nix.enable = true;

  nix.settings = {
    # Enable flakes + modern CLI
    experimental-features = [ "nix-command" "flakes" ];

    # System build group
    build-users-group = "nixbld";

    # Move ~/.nix-* into XDG directories
    use-xdg-base-directories = true;

    # Official binary cache
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # ------------------------------------------------------------
  # GLOBAL ENVIRONMENT VARIABLES
  # ------------------------------------------------------------
  environment.variables = {
    XDG_STATE_HOME = "$HOME/.config";
    XDG_DATA_HOME  = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.config";

    ESPANSO_DIR = "/Users/ven/ven-dots/espanso";
    ZDOTDIR = "/Users/ven/ven-dots/zsh";
  };

  # ------------------------------------------------------------
  # STATE VERSION
  # ------------------------------------------------------------
  system.stateVersion = 6;

  # ------------------------------------------------------------
  # SYSTEM PACKAGES
  # Core utilities with concise descriptions
  # ------------------------------------------------------------
  environment.systemPackages = with pkgs; [

    # darwin-rebuild binary
    inputs.darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild

    # New Bash
    bashInteractive
    
    # Bitwarden CLI
    bitwarden-cli

    # Git diff viewer with syntax highlighting
    delta

    # Fast alternative to find
    fd
    
    # Git Filtering
    git-filter-repo
    
    # Git Large Files Storage
    git-lfs

    # Git encryption tool
    git-crypt

    # Terminal UI helpers
    gum

    # Home Manager CLI
    home-manager
    
    # Tools for NSS certificates
    nssTools

    # Nix language server
    nixd

    # Nix formatter
    nil

    # Fast recursive search
    ripgrep

    # Directory tree viewer
    tree

    # YAML processor
    yq-go
  ];
}
