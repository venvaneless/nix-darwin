# /Users/ven/.config/nix/nix-config/darwin/modules/system/base.nix
#
# =====================================================================
# SYSTEM: BASE CONFIGURATION
#
# Defines the core nix-darwin system foundation:
# - Nix daemon and flake settings
# - Hostname and system state version
# - Global XDG environment paths
# - Homebrew system PATH entries
# - nixpkgs package policy
# - System module imports
# =====================================================================

{ ... }:

{
  # ------------------------------------------------------------
  # ------ SYSTEM AND NIX ------ #
  #
  # Core nix-darwin and Nix settings required for system builds,
  # flake support, store hygiene, and machine identity.
  # ------------------------------------------------------------

  # ---- Manage the Nix daemon
  # Ensures nix-darwin manages the nix-daemon service
  nix.enable = true;

  # ---- Hostname
  # Sets the machine name used by macOS and local networking
  networking.hostName = "Vens-MacBook-Pro";

  # ---- System state version
  # Tracks nix-darwin system compatibility defaults
  system.stateVersion = 6;

  # ---- Deduplicate store paths
  # Automatically optimizes the Nix store by hard-linking duplicates
  nix.optimise.automatic = true;

  # ---- Nix settings
  # Configures flakes, trusted users, build behavior, logs, and caches
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

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
    trusted-users = [ "root" "ven" ];

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
  # ------ GLOBAL ENVIRONMENT VARIABLES ------ #
  #
  # Defines XDG base directories globally so tools store config,
  # state, data, and cache files in predictable locations.
  # ------------------------------------------------------------

  # ---- XDG directories
  # Moves compatible application files into your preferred ~/.config layout
  environment.variables = {
    XDG_CONFIG_HOME = "/Users/ven/.config";
    XDG_STATE_HOME = "/Users/ven/.config/.state";
    XDG_DATA_HOME = "/Users/ven/.config/.local/share";
    XDG_CACHE_HOME = "/Users/ven/.config/.cache";
  };

  # ------------------------------------------------------------
  # ------ GLOBAL SYSTEM PATH ------ #
  #
  # Adds Homebrew paths globally so brew-installed binaries remain
  # available alongside Nix-managed tools.
  # ------------------------------------------------------------

  # ---- Homebrew binary paths
  # Makes Apple Silicon Homebrew commands available system-wide.
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  # ------------------------------------------------------------
  # ------ SYSTEM IMPORTS ------ #
  #
  # Loads additional system modules, including macOS options and
  # split package groups.
  # ------------------------------------------------------------

  # ---- Module imports
  # Keeps base.nix clean by loading related configuration from separate files
  imports = [
    ./system-options.nix

    # Shared host configuration

    # macOS-only packages
    ./packages/agents-pkgs.nix
    ./packages/tools-pkgs.nix

    # Shared
    ../../../shared/hosts.nix
    ../../../shared/packages/media-pkgs.nix

    # Not ready yet
    ./packages/cli-tools.nix
    ./packages/development-pkgs.nix
    ./packages/media-pkgs.nix
  ];
}