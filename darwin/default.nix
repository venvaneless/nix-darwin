# /Users/ven/.config/nix/nix-config/darwin/default.nix
#
# DARWIN: MAIN SYSTEM MODULE
# ================================================
# This file glues together:
#   - Core nix-darwin system configuration
#   - Integrated Home Manager configuration
#   - All system-level modules
#   - Homebrew, services, applications, and packages
#
# Notes:
#   - Home Manager is enabled only through nix-darwin
#   - No standalone Home Manager mode is used
#   - User-level modules live under darwin/modules/home
# ================================================

{ config, lib, home-manager, pkgs, ... }:

{
  # ------------------------------------------------------------
  # Primary user
  # ------------------------------------------------------------
  #
  # Main macOS user managed by nix-darwin.
  # Fish is set as the default login shell.
  # ------------------------------------------------------------

  system = {
    primaryUser = "ven";

    # Tracks nix-darwin system compatibility defaults
    stateVersion = lib.mkForce 6;
  };

  users = {
    knownUsers = [ "ven" ];

    users.ven = {
      uid = 502;
      home = "/Users/ven";
      shell = pkgs.fish;
    };
  };

  # ------------------------------------------------------------
  # Home Manager
  # ------------------------------------------------------------
  #
  # Home Manager runs fully through nix-darwin.
  # Backup files use the .bak extension.
  # ------------------------------------------------------------

  home-manager = {
    backupFileExtension = "bak";
  };

  # ------------------------------------------------------------
  # Fish shell
  # ------------------------------------------------------------

  programs.fish.enable = true;

  environment.shells = [
    pkgs.fish
  ];

  # ------------------------------------------------------------
  # System and Nix
  # ------------------------------------------------------------
  #
  # Core nix-darwin and Nix settings required for system builds,
  # flake support, store hygiene, and machine identity.
  # ------------------------------------------------------------

  # ---- Manage the Nix daemon
  # Ensures nix-darwin manages the nix-daemon service
  nix.enable = true;

  # ---- Remote build machines
  # Keeps nix-darwin from reloading the daemon when no remote builders are configured.
  environment.etc."nix/machines" = lib.mkIf (config.nix.buildMachines == []) {
    text = "";
  };

  # ---- Hostname
  # Sets the machine name used by macOS and local networking
  networking.hostName = "Vens-MacBook-Pro";

  # ---- Deduplicate store paths
  # Automatically optimizes the Nix store by hard-linking duplicates
  nix.optimise.automatic = true;

  # ---- Nix settings
  # Configures flakes, trusted users, build behavior, logs, and caches
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # System build group
    build-users-group = "nixbld";

    # Use XDG base directories for configuration, state, data, and cache
    # Moves compatible application files into your preferred ~/.config layout
    use-xdg-base-directories = true;

    # Ignore dirty git tree warnings
    warn-dirty = false;

    # Failure log length
    log-lines = 50;

    # Build job concurrency
    max-jobs = 4;

    # Limit cores per build
    cores = 2;

    # Build locally if cache fails
    fallback = true;

    # Allow trusted users
    trusted-users = [
      "root"
      "ven"
    ];

    # Keep build recipes
    keep-derivations = true;

    # Keep build results
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
  # Global environment variables
  # ------------------------------------------------------------
  #
  # Defines XDG base directories globally so tools store config,
  # state, data, and cache files in predictable locations.
  # ------------------------------------------------------------

  # ---- XDG directories
  # Moves compatible application files into your preferred ~/.config layout
  environment.variables = {
  	# XDG base directories
    XDG_CONFIG_HOME = "/Users/ven/.config";
    XDG_STATE_HOME = "/Users/ven/.config/.state";
    XDG_DATA_HOME = "/Users/ven/.config/.local/share";
    XDG_CACHE_HOME = "/Users/ven/.config/.cache";
  };

  # ------------------------------------------------------------
  # Global system path
  # ------------------------------------------------------------
  #
  # Adds Homebrew paths globally so brew-installed binaries remain
  # available alongside Nix-managed tools.
  # ------------------------------------------------------------

  # ---- Homebrew binary paths
  # Makes Apple Silicon Homebrew commands available system-wide
  environment.systemPath = [
  	# Add Homebrew binary and sbin paths to the system PATH
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  # ------------------------------------------------------------
  # Module imports
  # ------------------------------------------------------------
  #
  # Loads all Home Manager, system, service, and application modules.
  # ------------------------------------------------------------

  imports = [
    # Home Manager
    home-manager.darwinModules.home-manager
    ./home/home-manager.nix

    # System options
    ./system/system-options.nix
    ./system-commands

    # macOS-only packages
    ./packages/agents-pkgs.nix
    ./packages/tools-pkgs.nix
    ./packages/cli-tools.nix
    ./packages/media-pkgs.nix
    
    # Shared host configuration and packages
    ../shared/hosts.nix
    ../shared/packages/media-pkgs.nix
    ../shared/packages/development-pkgs.nix
    ../shared/packages/productivity-pkgs.nix

    # Homebrew
    ./system/homebrew.nix

    # Services
    ./services/services.nix
  ];
}
