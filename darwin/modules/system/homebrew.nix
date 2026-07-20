# /Users/ven/.config/nix/nix-config/darwin/modules/system/homebrew.nix
  #
  # ==========================================================
  # HOMEBREW: UNIFIED PACKAGE MANAGER
  #
  # Bootstraps Homebrew through nix-homebrew and manages declarative
  # brews, casks, taps, and activation cleanup for nix-darwin.
  # ==========================================================
  
  { config, lib, pkgs, nix-homebrew, ... }:
  
  let
    generatedBrewfile = pkgs.writeText "nix-darwin-Brewfile" config.homebrew.brewfile;
  in

  {
    # -----------------------------------------------------
    # ------ HOMEBREW: MODULE IMPORTS ----- #
    # Load the nix-homebrew module used by nix-darwin
    # -----------------------------------------------------
  
    imports = [
      nix-homebrew.darwinModules.nix-homebrew
      # ./quarantine-fixes.nix
    ];
  
    # -----------------------------------------------------
  
  
    # -----------------------------------------------------
    # ------ HOMEBREW: BACKEND ----- #
    # Configure the Homebrew installation and migration behavior
    # -----------------------------------------------------
  
    nix-homebrew = {
      enable = true;
      user = "ven";
      enableRosetta = false;
      autoMigrate = true;
    };
  
    # -----------------------------------------------------
  
  
    # -----------------------------------------------------
    # ------ HOMEBREW: PACKAGES ----- #
    # Declaratively manage Homebrew taps, brews, and casks
    # -----------------------------------------------------
  
    homebrew = {
      enable = true;
  
      global.autoUpdate = true;

      onActivation = { 
        autoUpdate = false;

        # Disable nix-darwin's currently broken integrated cleanup flag.inherit
        # Cleanup is separately handled below.
        cleanup = "none";

        upgrade = true;
      };
  
      # CASK INSTALL LOCATION
      # -----------------------------------------------------
  
      caskArgs = {
        appdir = "/Applications";
      };
  
  
      # HOMEBREW TAPS
      # -----------------------------------------------------
  
      taps = [
        "binary-beam/tap"
        "lutzifer/homebrew-tap"
        # "Ducksss/tap"
      ];
  
  
      # HOMEBREW FORMULAS
      # -----------------------------------------------------
  
      brews = [
        "lutzifer/homebrew-tap/keyboardSwitcher"

        # "Ducksss/tap/codex-profile"
      ];
  
  
      # HOMEBREW CASKS
      # -----------------------------------------------------
  
      casks = [
  
        # Browsers
        "librewolf"
        "ungoogled-chromium"
  
        # Books and offline libraries
        "calibre"
  
        # Communication
        "vesktop"
  
        # Media
        "freetube"
  
        # System utilities
        "swiftdialog"
        "syncthing-app"
        "thaw"
      ];
    };

    # -----------------------------------------------------
    # ------ HOMEBREW: CLEANUP ----- #
    # Remove unused Homebrew packages and casks
    # -----------------------------------------------------

    system.activationScripts.homebrew.text = lib.mkAfter ''
      echo "Homebrew cleanup..."
    
      if [ -x /opt/homebrew/bin/brew ]; then
        sudo \
          --preserve-env=PATH \
          --user=ven \
          --set-home \
          /opt/homebrew/bin/brew bundle cleanup \
            --file=${generatedBrewfile} \
            --force
      else
        echo "Homebrew is not installed, skipping cleanup." >&2
      fi
    '';
    # -----------------------------------------------------
}