# darwin/default.nix
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

{ config, lib, home-manager, paths, pkgs, ... }:

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

  # ---- Nix settings
  # Configures flakes, trusted users, build behavior, logs, and caches
  #
  # ** This machine's own values. What is the same on every machine --
  # ** flakes, the caches, dirty warnings -- is written once in
  # ** shared/nix-options.nix and is not repeated here.
  #
  # ** Any of these may be written as default instead, which takes the
  # ** value declared in options/nix-options.nix. Written out here so the
  # ** file says what this Mac actually runs.
  ven.nix.settings = {
    # System build group
    build-users-group = "nixbld";

    # Use XDG base directories for Nix's own files
    # ** Only the user profile and channels. Where other tools look is set
    # ** by the XDG_* variables further down, which are a separate thing.
    use-xdg-base-directories = true;

    # Failure log length
    log-lines = 50;

    # Build job concurrency
    max-jobs = 4;

    # Limit cores per build
    cores = 2;

    # Build locally if cache fails
    fallback = true;

    # Allow trusted users
    # ** Add a name to this list to trust another account. A trusted user
    # ** may hand the daemon privileged options, including extra
    # ** substituters and trusted keys, which is close to root. Never list
    # ** an account you would not give sudo.
    trusted-users = [
      "root"
      paths.user.name
    ];

    # Keep build recipes
    keep-derivations = true;

    # Keep build results
    keep-outputs = true;

    # Deduplicate store paths by hard-linking duplicates
    # ** A scheduled service rather than a setting: launchd here, systemd
    # ** on the NixOS machines.
    optimise.automatic = true;
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
    ./home

    # System options
    ./system/system-options.nix
    ./system-commands

    # Shared system commands
    (import ../shared/system-commands/obsidian-archive-check.nix {
      installTarget = "system";
    })

    # macOS-only packages
    ./packages/agents-pkgs.nix
    ./packages/tools-pkgs.nix
    
    # Shared packages
    # The nixpkgs policy comes from options/default.nix, applied in
    # flake-modules/macbook.nix. Modules needing the unstable set read
    # unstablePkgs from options/default.nix directly.
    # The package helper arrives through flake-level special arguments.
    ../shared/packages.nix

    # Homebrew
    ./system/homebrew.nix

    # Services
    ./services/services.nix
  ];
}
