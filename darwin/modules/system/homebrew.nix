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

        # Disable nix-darwin's integrated cleanup.
        # Cleanup is separately handled below.
        cleanup = "none";

        upgrade = true;
      };

      # MAC APP STORE APPLICATIONS
      # -----------------------------------------------------
      
      masApps = {
        SnippetsLab = 1006087419;
      };
      
      # CASK INSTALL LOCATION
      # -----------------------------------------------------
  
      caskArgs = {
        appdir = "/Applications";
      };
  
  
      # HOMEBREW TAPS
      # -----------------------------------------------------
  
      taps = [
        "lutzifer/homebrew-tap"
      ];
  
  
      # HOMEBREW FORMULAS
      # -----------------------------------------------------
  
      brews = [
        "lutzifer/homebrew-tap/keyboardSwitcher"
      ];
  
  
      # HOMEBREW CASKS
      # -----------------------------------------------------
      
      casks = [
        # Browsers
        "librewolf"
        "ungoogled-chromium"
      
        # Multimedia
        {
          name = "calibre";
          args = {
            appdir = "/Applications/Multimedia";
          };
        }
      
        {
          name = "freetube";
          args = {
            appdir = "/Applications/Multimedia";
          };
        }
      
        # Communication
        "vesktop"
      
        # System utilities
        "swiftdialog"
      
        {
          name = "syncthing-app";
          args = {
            appdir = "/Applications/Tools";
          };
        }
      
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