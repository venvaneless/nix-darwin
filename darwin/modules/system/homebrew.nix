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
    casksFor = appdir: names:
      map (name: {
        inherit name;
        args = {
          inherit appdir;
        };
      }) names;
  in

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
      # Enable the nix-homebrew module to bootstrap Homebrew on macOS
      enable = true;

      # Set the user for Homebrew installation and migration
      user = "ven";

      # Disable Rosetta migration for Homebrew on Apple Silicon
      enableRosetta = false;

      # Enable automatic migration of Homebrew packages from Intel to Apple Silicon architecture
      autoMigrate = true;
    };
   	# ---------------------------------------------------------


   	# ---------------------------------------------------------
    # ------ HOMEBREW: PACKAGES ----- #
    # Declaratively manage Homebrew taps, brews, and casks
   	# ---------------------------------------------------------

    # ---- HOMEBREW SETTINGS
    homebrew = {
      # Enable the Homebrew module to manage packages and casks
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
        # Utility used by Raycast to switch keyboard layouts
        "lutzifer/homebrew-tap/keyboardSwitcher"
      ];
    # ---------------------------------------------------------


   	# ---------------------------------------------------------
    # HOMEBREW CASKS
   	# ---------------------------------------------------------
      casks =
        [
          # Browsers
          "librewolf"
          "ungoogled-chromium"

          # Discord client
          "vesktop"

          # System utilities

          ## macOS Dialog library for SwiftUI and AppKit
          "swiftdialog"

          ## macOS statusbar tool for hiding and showing menu bar icons
          "thaw"
        ]
        ++ casksFor "/Applications/Multimedia" [
          # Ebook management application
          "calibre"

          # Privacy-friendly YouTube desktop client
          "freetube"

          # macOS Media file tag editor
          "yate"
        ]
        ++ casksFor "/Applications/Productivity" [
          # Knowledge base that works on top of a local folder
          # of plain text Markdown files
          "obsidian"

          # A collection of powerful productivity tools all within
          # an extendable macOS launcher
          "raycast"

          # Simple note-taking app written in React
          "simplenote"

          # Multiplayer code editor written in Rust
          "zed"
        ]
        ++ casksFor "/Applications/Programming" [
          # API documentation viewer
          "dteoh-devdocs"

          # Utilities designed to make common development tasks easier
          "devtoys"

          # Open-source code editor
          "visual-studio-code"

          # GPU-accelerated cross-platform terminal emulator and multiplexer
          "wezterm"
        ]
        ++ casksFor "/Applications/System" [
          # Open-source Chromium-based web browser
          "helium-browser"

          # Utility to uninstall apps and remove leftover files from
          # old/uninstalled apps
          "pearcleaner"
        ]
        ++ casksFor "/Applications/Tools" [
          # Cross-platform Text Expander written in Rust
          "espanso"

          # Download manager
          "jdownloader"

          # Your clipboard, supercharged and secure Paste keeps everything
          # you copy organized and searchable. Lightweight, intuitive,
          # packed with smart features, and private by design
          "paste"

          "syncthing-app"
        ];
    };
   	# ---------------------------------------------------------


    # ****************************************************************
    # ------ HOMEBREW: CLEANUP AND APP LOCATION ------ #
    # Remove undeclared packages and move SnippetsLab
    # ****************************************************************

    system.activationScripts.homebrew.text = lib.mkAfter ''
   	# ---------------------------------------------------------
    # Ensure custom application directories exist
    # ---------------------------------------------------------

      ${pkgs.coreutils}/bin/mkdir -p \
        -- \
        "/Applications/Multimedia" \
        "/Applications/Productivity" \
        "/Applications/Programming" \
        "/Applications/System" \
        "/Applications/Tools"
    # ---------------------------------------------------------


    # ****************************************************************
    # ------ HOMEBREW: CLEANUP AND APP LOCATION ------ #
    # Remove undeclared packages and move SnippetsLab
    # ****************************************************************

    system.activationScripts.homebrew.text = lib.mkAfter ''
   	# ---------------------------------------------------------
    # Homebrew cleanup
    # ---------------------------------------------------------

      # Print a message indicating that Homebrew cleanup is starting
      echo "Homebrew cleanup..."

      # Check if Homebrew is installed by verifying the existence of the brew executable
      if [ -x /opt/homebrew/bin/brew ]; then
        generatedBrewfile=${lib.escapeShellArg config.environment.variables.HOMEBREW_BUNDLE_FILE}

        # Check if the generated Brewfile exists before proceeding with cleanup
        if [ ! -f "$generatedBrewfile" ]; then
          echo "Generated Brewfile was not found: $generatedBrewfile" >&2
          exit 1
        fi

        # Run Homebrew cleanup as the Homebrew owner
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
      	# Print a message indicating that Homebrew is not installed and cleanup is being skipped
        echo "Homebrew is not installed, skipping cleanup." >&2
      fi
    # ---------------------------------------------------------


   	# ---------------------------------------------------------
    # SnippetsLab application location
    # ---------------------------------------------------------

      # Set variables for the source and target locations for the application
      snippetsLabSource="/Applications/SnippetsLab.app"
      snippetsLabTargetDirectory="/Applications/Programming"
      snippetsLabTarget="$snippetsLabTargetDirectory/SnippetsLab.app"

      # Check if the source directory exists
      if [ -d "$snippetsLabSource" ]; then
        ${pkgs.coreutils}/bin/mkdir -p \
          -- "$snippetsLabTargetDirectory"

        # Check if the target is a symbolic link, and if so, remove it
        if [ -L "$snippetsLabTarget" ]; then
          echo "[SnippetsLab] Removing old symbolic link: $snippetsLabTarget"

          # Remove the symbolic link using coreutils' rm command
          ${pkgs.coreutils}/bin/rm -f \
            -- "$snippetsLabTarget"
        elif [ -e "$snippetsLabTarget" ]; then
          echo "[SnippetsLab] Target already exists: $snippetsLabTarget" >&2
          echo "[SnippetsLab] Source was not moved." >&2
          exit 1
        fi

        # Move the SnippetsLab application from the source to the target location
        /bin/mv \
          "$snippetsLabSource" \
          "$snippetsLabTarget"

        echo "[SnippetsLab] Moved: $snippetsLabSource -> $snippetsLabTarget"
      elif [ -d "$snippetsLabTarget" ]; then
        echo "[SnippetsLab] Already in Programming."
      else
        echo "[SnippetsLab] Application not found." >&2

        # Search for any SnippetsLab application in the /Applications directory
        /usr/bin/find /Applications \
          -maxdepth 2 \
          -type d \
          -iname '*snippet*.app' \
          -print >&2
      fi
    '';
   	# ---------------------------------------------------------
  }