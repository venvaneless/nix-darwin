# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/base.nix
#
{ config, pkgs, lib, inputs, ... }:

{
  # ------------------------------------------------------------
  # SYSTEM IMPORTS
  # ------------------------------------------------------------
  imports = [
    ./system-options.nix
  ];

  # ------------------------------------------------------------
  # SYSTEM AND NIX
  # ------------------------------------------------------------

  # ---- Manage the Nix daemon ----
  # ---------------------------------------------------------
  # Ensures the nix-daemon launchd service exists
  # Starts it at boot
  # Keeps it in sync with your config
  # Without it, nix-darwin can’t reliably control
  # builds, users, or settings
  # ---------------------------------------------------------
  nix.enable = true;
  
  # ---- Hostname ----
  networking.hostName = "Vens-MacBook-Pro";
  
  # ---- System State Version ----
  system.stateVersion = 6;
  
  # ---- Allow unfree packages ----
  nixpkgs.config.allowUnfree = true;
  
  # ---- Deduplicate store paths
  nix.optimise.automatic = true;
  
  nix.settings = {
  
    # ------ Flakes + modern CLI ------
    experimental-features = [ "nix-command" "flakes" ];
    
    # ------ System build group ------
    build-users-group = "nixbld";
    
    # Move ~/.nix-* into XDG directories
    use-xdg-base-directories = true;
    
    # ------ LOGS ------
    
    # --- Ignore dirty git tree warnings
    warn-dirty = false;
    
    # --- Failure log length
    log-lines = 50;
  
  
    # ------ BUILD PERFORMANCE ------
    
    # ---- Use all CPU cores
    max-jobs = 4;
    
    # ---- Limit cores per build
    cores = 2;
    
    # ---- Build locally if cache fails
    fallback = true;
        
    # ---- Allow trusted users
    trusted-users = [ "root" "ven" ];
  
  
    # ------ STORE HYGIENE ------
    
    # ---- Keep build recipes
    keep-derivations = true;
    
    # ---- Keep build results
    keep-outputs = true;
  
    # ---- Official binary cache ----
    substituters = [
      "https://cache.nixos.org"
    ];
  
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
  
  # Temporary - Allow unfree packages
  
  # ------------------------------------------------------------
  # GLOBAL ENVIRONMENT VARIABLES
  # ------------------------------------------------------------
  environment.variables = {
  	XDG_CONFIG_HOME = "/Users/ven/ven-dots/conf";
   	XDG_STATE_HOME  = "/Users/ven/ven-dots/state";
    XDG_DATA_HOME   = "/Users/ven/ven-dots/data";
    XDG_CACHE_HOME  = "/Users/ven/ven-dots/cache";
  };
  
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
    
    # Yazi
    
    # YAML processor
    yq-go
  ];
}