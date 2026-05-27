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


  # ------------------------------------------------------------
  # GLOBAL ENVIRONMENT VARIABLES
  # ------------------------------------------------------------
  environment.variables = {
  	XDG_CONFIG_HOME = "/Users/ven/.config";
   	XDG_STATE_HOME  = "/Users/ven/.config/.state";
    XDG_DATA_HOME   = "/Users/ven/.config/.local/share";
    XDG_CACHE_HOME  = "/Users/ven/.config/.cache";
  };

  

  # ------------------------------------------------------------
  # NIXPKGS PACKAGE POLICY
  # ------------------------------------------------------------
  nixpkgs.config = {
    # Allow packages with non-free licenses.
    allowUnfree = true;

    # Temporarily allow Colima's current Lima dependency.
    permittedInsecurePackages = [
      "lima-full-1.2.2"
    ];
  };

  # ------------------------------------------------------------
  # SYSTEM PACKAGES
  # Core utilities with concise descriptions
  # ------------------------------------------------------------
  environment.systemPackages = with pkgs; [

    # darwin-rebuild binary
    inputs.darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild

    # Shell history sync and search
    atuin

    # Cat clone with syntax highlighting and Git integration
    bat
    
    # New Bash
    bashInteractive

    # Bitwarden CLI
    bitwarden-cli

    # Cross-platform graphical process/system monitor
    bottom

    # Container runtimes on MacOS
    colima

    # Docker CLI
    docker-client
    
    # Modern, maintained replacement for ls
    eza
    
    # Git diff viewer with syntax highlighting
    delta

    # System information fetch tool
    fastfetch
    
    # Fast alternative to find
    fd

    # Friendly interactive shell
    fish
    
    # Create thumbnails for your video files
    ffmpegthumbnailer

    # GNU Awk text processing tool
    gawk
    # Git encryption tool
    git-crypt

    # Git Filtering
    git-filter-repo

    # Git Large File Storage
    git-lfs

    # Terminal UI helpers
    gum

    # Home Manager CLI
    home-manager
    
    # Tools and libraries to manipulate images in select formats
    imagemagick

    # Terminal UI for Git
    lazygit
    
    # Supplies technical and tag information about a video or audio file
    mediainfo

    # Terminal text editor
    micro

    # Nix formatter
    nil
    
    # Nix search database
    nix-index

    # Nix language server
    nixd

    # Tools for NSS certificates
    nssTools
    
    # 7-Zip (high compression file archiver) implementation
    p7zip
    
    # PDF rendering library
    poppler
    
    # Fast recursive search tool
    ripgrep

    # Directory tree viewer
    tree
    
    # Command-line unarchiving tools supporting multiple formats
    unar

    # Terminal file manager
    ranger

    # Smarter directory jumping
    zoxide

    # Terminal multiplexer
    tmux

    # Zsh history substring search widget
    zsh-history-substring-search
  ];
}
