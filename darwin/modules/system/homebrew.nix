# /Users/ven/.config/nix/nix-config/darwin/modules/system/homebrew.nix
  #
  # ==========================================================
  # HOMEBREW: UNIFIED PACKAGE MANAGER
  #
  # Bootstraps Homebrew through nix-homebrew and manages declarative
  # brews, casks, taps, and activation cleanup for nix-darwin.
  # ==========================================================
  
  { config, lib, pkgs, nix-homebrew, ... }:
  
  {
  
 	# ---------------------------------------------------------
    # -------- HOMEBREW: MODULE IMPORTS ------- #
    # Load the nix-homebrew module used by nix-darwin
   	# ---------------------------------------------------------
    imports = [
      nix-homebrew.darwinModules.nix-homebrew
      # ./quarantine-fixes.nix
    ];
   	# ---------------------------------------------------------
  
  
   	# ---------------------------------------------------------
    # ------ HOMEBREW: BACKEND ----- #
    # Configure the Homebrew installation and migration behavior
   	# ---------------------------------------------------------
    nix-homebrew = {
      enable = true;
      user = "ven";
      enableRosetta = false;
      autoMigrate = true;
    };
   	# ---------------------------------------------------------
  
  
   	# ---------------------------------------------------------
    # ------ HOMEBREW: PACKAGES ----- #
    # Declaratively manage Homebrew taps, brews, and casks
   	# ---------------------------------------------------------

    # ---- HOMEBREW SETTINGS
    homebrew = {
      enable = true;

      global = {
        # Enable automatic updates for manually run Homebrew commands
        autoUpdate = true;

        # Expose nix-darwin's generated Brewfile
        brewfile = true;
      };

      onActivation = { 
      	# Disable automatic updates during activation
        autoUpdate = false;

        # Disable nix-darwin's integrated cleanup.
        # Cleanup is separately handled below.
        cleanup = "none";

		# Disable automatic upgrades during activation        
        upgrade = false;

        	# Disable environment hints during activation
            extraEnv = {
              HOMEBREW_NO_ENV_HINTS = "1";
            };
          };
    # ---------------------------------------------------------


    # ****************************************************************
    # ------ MACOS PACKAGE MANAGEMENT ----- #
    # ****************************************************************

   	# ---------------------------------------------------------
    # ---- MAC APP STORE APPLICATIONS
    # ---------------------------------------------------------
      masApps = {
        # SnippetsLab = 1006087419;
      };
    # ---------------------------------------------------------


    # ---------------------------------------------------------
    # ---- CASK INSTALL LOCATION
    # ---------------------------------------------------------
      caskArgs = {
        appdir = "/Applications";
      };
    # ---------------------------------------------------------

  
   	# ---------------------------------------------------------
    # ---- HOMEBREW TAPS
   	# ---------------------------------------------------------
  
      taps = [
        {
          name = "lutzifer/homebrew-tap";
          trusted = true;
        }
      ];
    # ---------------------------------------------------------

      
   	# ---------------------------------------------------------
    # ---- HOMEBREW FORMULAS
   	# ---------------------------------------------------------
  
      brews = [
        "lutzifer/homebrew-tap/keyboardSwitcher"
      ];
    # ---------------------------------------------------------


   	# ---------------------------------------------------------
    # HOMEBREW CASKS
   	# ---------------------------------------------------------
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
   	# ---------------------------------------------------------

    
    # ****************************************************************
    # ------ HOMEBREW: CLEANUP AND APP LOCATION ------ #
    # Remove undeclared packages and move SnippetsLab
    # ****************************************************************    
    echo "Homebrew cleanup..."

    if [ -x /opt/homebrew/bin/brew ]; then
      generatedBrewfile=${lib.escapeShellArg config.environment.variables.HOMEBREW_BUNDLE_FILE}

      if [ ! -f "$generatedBrewfile" ]; then
        echo "Generated Brewfile was not found: $generatedBrewfile" >&2
        exit 1
      fi

      PATH="/opt/homebrew/bin:${pkgs.mas}/bin:$PATH" \
        sudo \
          --preserve-env=PATH \
          --user=ven \
          --set-home \
          env \
            HOMEBREW_NO_AUTO_UPDATE=1 \
            HOMEBREW_NO_ENV_HINTS=1 \
            /opt/homebrew/bin/brew bundle cleanup \
              --file="$generatedBrewfile" \
              --force
    else
      echo "Homebrew is not installed, skipping cleanup." >&2
    fi
    # ****************************************************************