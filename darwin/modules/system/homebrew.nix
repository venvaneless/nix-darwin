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

        upgrade = false;
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
    # ------ HOMEBREW: CLEANUP AND APP LOCATION ----- #
    # Remove undeclared packages and move SnippetsLab
    # -----------------------------------------------------

    system.activationScripts.homebrew.text = lib.mkAfter ''
      # ---------------------------------------------------
      # Homebrew cleanup
      # ---------------------------------------------------

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


      # ---------------------------------------------------
      # SnippetsLab application location
      # ---------------------------------------------------

      snippetsLabSource="/Applications/SnippetsLab.app"
      snippetsLabTargetDirectory="/Applications/Programming"
      snippetsLabTarget="$snippetsLabTargetDirectory/SnippetsLab.app"

      if [ -d "$snippetsLabSource" ]; then
        ${pkgs.coreutils}/bin/mkdir -p \
          -- "$snippetsLabTargetDirectory"

        if [ -L "$snippetsLabTarget" ]; then
          echo "[SnippetsLab] Removing old symbolic link: $snippetsLabTarget"

          ${pkgs.coreutils}/bin/rm -f \
            -- "$snippetsLabTarget"
        elif [ -e "$snippetsLabTarget" ]; then
          echo "[SnippetsLab] Target already exists: $snippetsLabTarget" >&2
          echo "[SnippetsLab] Source was not moved." >&2
          exit 1
        fi

        /bin/mv \
          "$snippetsLabSource" \
          "$snippetsLabTarget"

        echo "[SnippetsLab] Moved: $snippetsLabSource -> $snippetsLabTarget"
      elif [ -d "$snippetsLabTarget" ]; then
        echo "[SnippetsLab] Already in Programming."
      else
        echo "[SnippetsLab] Application not found." >&2

        /usr/bin/find /Applications \
          -maxdepth 2 \
          -type d \
          -iname '*snippet*.app' \
          -print >&2
      fi
    '';
}