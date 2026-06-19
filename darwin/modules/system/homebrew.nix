# /Users/ven/.config/nix/nix-config/darwin/modules/system/homebrew.nix
#
# HOMEBREW: UNIFIED PACKAGE MANAGER
# ============================================================
# Bootstraps Homebrew through nix-homebrew and manages declarative
# brews, casks, taps, and activation cleanup for nix-darwin.
# ============================================================

{ nix-homebrew, ... }:

{
  # HOMEBREW: MODULE IMPORTS
  # ============================================================
  # Load the nix-homebrew module used by nix-darwin.
  imports = [
    nix-homebrew.darwinModules.nix-homebrew
    # ./quarantine-fixes.nix
  ];

  # HOMEBREW: BACKEND
  # ============================================================
  # Configure the nix-homebrew installation and migration behavior.
  nix-homebrew = {
    enable = true;
    user = "ven";
    enableRosetta = false;
    autoMigrate = true;
  };

  # HOMEBREW: PACKAGES
  # ============================================================
  # Declaratively manage Homebrew taps, brews, and casks.
  homebrew = {
    enable = true;

    global.autoUpdate = true;

    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
    };

    taps = [
      "binary-beam/tap"
    ];

    brews = [
    ];

    casks = [
      {
        name = "ungoogled-chromium";
        args = {
          appdir = "/Applications";
        };
      }

      {
        name = "swiftdialog";
      }
    ];
  };
}