# darwin/home/default.nix
#
# =====================================================================
# DARWIN: HOME MANAGER (INTEGRATED)
# =====================================================================
{
  inputs,
  paths,
  pkgs,
  platforms,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs paths platforms;
    };

    # Provides the Home Manager sops.* options used by shared/secrets.nix.
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
    ];

    # ------------------------------------------------------------
    # User
    # ------------------------------------------------------------
    users.ven = {
      home.username = "ven";
      home.homeDirectory = "/Users/ven";
      home.stateVersion = "26.05";

      # ------------------------------------------------------------
      # Home Manager packages
      # ------------------------------------------------------------
      home.packages = [
        # bat is installed by shared/terminal/cli-tuis/bat/bat.nix
        pkgs.python312Packages.internetarchive
      ];

      # ------------------------------------------------------------
      # Espanso
      # ------------------------------------------------------------
      # The shared Espanso module declares these knobs and renders the
      # configuration files. This Mac chooses their concrete values.
      ven.espanso = {
        enable = true;
        showNotifications = true;

        base.enable = true;

        markdown = {
          enable = true;

          links = {
            enable = true;

            standard = {
              enable = true;
              trigger = ":mdlink";
              title = "Title";
              link = "Link";
            };

            obsidian = {
              enable = true;
              trigger = ":wikilink";
              text = "Text";
            };

            obsidianAlias = {
              enable = false;
              trigger = ":wikialias";
              link = "Link";
              title = "Title";
            };

            autolink = {
              enable = false;
              trigger = ":mdurl";
              link = "Link";
            };

            image = {
              enable = false;
              trigger = ":mdimage";
              alt = "Alt text";
              link = "Image URL";
            };
          };

          formatting = {
            enable = true;

            bold = {
              enable = true;
              trigger = ":mdbold";
              text = "Text";
            };

            task = {
              enable = true;
              trigger = ":mdtask";
            };
          };
        };
      };

      # Espanso needs these custom paths in its user LaunchAgent. Use the
      # Nix package binary rather than the mutable /Applications symlink.
      launchd.agents.espanso = {
        config = {
          Label = "com.federicoterzi.espanso";
          ProgramArguments = [
            "${pkgs.espanso}/bin/espanso"
            "launcher"
          ];
          RunAtLoad = true;
          EnvironmentVariables = {
            ESPANSO_CONFIG_DIR = paths.darwin.home.espanso.config;
            ESPANSO_DATA_DIR = "${paths.darwin.home.espanso.config}/data";
          };
        };
      };

      # ------------------------------------------------------------
      # Darwin Home Manager defaults
      # ------------------------------------------------------------

      targets.darwin.defaults = {
        NSGlobalDomain = {
          # Preferred UI languages, in priority order
          AppleLanguages = [
            "en"
            "de"
            "pl"
          ];

          # Locale used for dates, numbers, etc.
          AppleLocale = "en_DE";

          # Measurement units
          AppleMeasurementUnits = "Centimeters";

          # Menu bar visibility: hides the menu bar until the pointer reaches it.
          _HIHideMenuBar = true;

          # Window animations: disables most automatic window-opening animations.
          NSAutomaticWindowAnimationsEnabled = false;

          # Window resize speed: makes resize animations nearly immediate.
          NSWindowResizeTime = 0.001;

          # Function keys: uses F1–F12 as standard function keys by default.
          "com.apple.keyboard.fnState" = true;

          # Automatic capitalization: capitalizes the first word of sentences.
          NSAutomaticCapitalizationEnabled = true;

          # Smart quotes: replaces straight quotation marks with typographic quotes.
          NSAutomaticQuoteSubstitutionEnabled = true;

          # Smart dashes: replaces double hyphens with typographic dashes.
          NSAutomaticDashSubstitutionEnabled = true;

          # Automatic periods: disables double-space period insertion.
          NSAutomaticPeriodSubstitutionEnabled = false;

          # Spell correction: disables automatic spelling corrections.
          NSAutomaticSpellingCorrectionEnabled = false;

          # Scroll direction: uses traditional rather than natural scrolling.
          "com.apple.swipescrolldirection" = false;

          # Global tap to click: leaves the system default unchanged.
          "com.apple.mouse.tapBehavior" = null;
        };

        # Accessibility preferences for Ven's desktop session.
        "com.apple.universalaccess" = {
          # Transparency: keeps macOS transparency effects enabled.
          reduceTransparency = false;

          # Motion: keeps macOS motion and animation effects enabled.
          reduceMotion = false;

          # Pointer size: sets the cursor to a larger-than-default size.
          mouseDriverCursorSize = 2.0;
        };

        # Trackpad preferences are written to both macOS user domains so
        # the built-in and Bluetooth trackpads use the same behaviour.
        "com.apple.AppleMultitouchTrackpad" = {
          ActuateDetents = true;
          ActuationStrength = 1;
          Clicking = false;
          DragLock = false;
          Dragging = true;
          FirstClickThreshold = 1;
          ForceSuppressed = false;
          SecondClickThreshold = 1;
          TrackpadCornerSecondaryClick = 2;
          TrackpadRightClick = false;
          TrackpadThreeFingerDrag = true;
          TrackpadMomentumScroll = true;
          TrackpadTwoFingerDoubleTapGesture = true;
          TrackpadPinch = false;
          TrackpadRotate = false;
          TrackpadFourFingerHorizSwipeGesture = 2;
          TrackpadFourFingerPinchGesture = 2;
          TrackpadFourFingerVertSwipeGesture = 2;
          TrackpadThreeFingerHorizSwipeGesture = 1;
          TrackpadThreeFingerTapGesture = 0;
          TrackpadThreeFingerVertSwipeGesture = 0;
          TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
        };

        "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
          ActuateDetents = true;
          ActuationStrength = 1;
          Clicking = false;
          DragLock = false;
          Dragging = true;
          FirstClickThreshold = 1;
          ForceSuppressed = false;
          SecondClickThreshold = 1;
          TrackpadCornerSecondaryClick = 2;
          TrackpadRightClick = false;
          TrackpadThreeFingerDrag = true;
          TrackpadMomentumScroll = true;
          TrackpadTwoFingerDoubleTapGesture = true;
          TrackpadPinch = false;
          TrackpadRotate = false;
          TrackpadFourFingerHorizSwipeGesture = 2;
          TrackpadFourFingerPinchGesture = 2;
          TrackpadFourFingerVertSwipeGesture = 2;
          TrackpadThreeFingerHorizSwipeGesture = 1;
          TrackpadThreeFingerTapGesture = 0;
          TrackpadThreeFingerVertSwipeGesture = 0;
          TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
        };

        # Mouse tracking speed: sets pointer movement speed for a physical mouse.
        ".GlobalPreferences"."com.apple.mouse.scaling" = 2.0;

        # Dock preferences; persistent applications stay in nix-darwin because
        # its typed option converts application paths into Dock tile data.
        "com.apple.dock" = {
          # Icon size: sets the normal Dock icon size in pixels.
          tilesize = 72;

          # Icon magnification: enlarges icons when the pointer hovers over them.
          magnification = true;

          # Magnified icon size: sets the hover magnification size in pixels.
          largesize = 80;

          # Dock auto-hide: hides the Dock until the pointer reaches its edge.
          autohide = true;

          # Dock position: places the Dock at the bottom of the display.
          orientation = "bottom";

          # Launch animation: disables application launch bouncing animation.
          launchanim = false;

          # Minimize effect: uses the scale animation when minimizing windows.
          mineffect = "scale";

          # Minimize destination: keeps minimized windows as separate Dock tiles.
          minimize-to-application = false;

          # Running indicators: shows the dot below open applications.
          show-process-indicators = true;

          # Recent apps: shows recently used apps that are not pinned to the Dock.
          show-recents = true;

          # Hidden app appearance: makes hidden application icons translucent.
          showhidden = true;

          # Spring loading: allows folders in the Dock to open while dragging files.
          enable-spring-load-actions-on-all-items = true;

          # Mission Control grouping: groups windows by application in Exposé.
          expose-group-apps = true;

          # Stack hover highlight: highlights an item when hovering over a stack.
          mouse-over-hilite-stack = true;

          # Scroll to Exposé: scrolling on an app icon opens that app's windows.
          scroll-to-open = true;

          # Dynamic Dock: keeps spaces and app behaviour dynamic rather than static.
          static-only = false;
        };

        "com.apple.finder" = {
          # Hidden files: shows files and folders normally hidden by Finder.
          AppleShowAllFiles = true;

          # Empty Trash: disables automatic deletion of Trash items after 30 days.
          FXRemoveOldTrashItems = false;

          # New Finder window target: opens new windows at a custom location.
          NewWindowTarget = "Other";

          # New Finder window location: uses the standard macOS Downloads folder.
          NewWindowTargetPath = "file://${paths.darwin.home.downloads}/";

          # Preferred view: uses List view for newly opened Finder windows.
          FXPreferredViewStyle = "Nlsv";

          # Folder sorting: keeps folders before files in Finder lists.
          _FXSortFoldersFirst = true;

          # Default search scope: searches the current folder by default.
          FXDefaultSearchScope = "SCcf";

          # File extensions: always displays filename extensions.
          AppleShowAllExtensions = true;

          # Extension warnings: disables warnings when changing file extensions.
          FXEnableExtensionChangeWarning = false;

          # Path bar: displays the current folder hierarchy at the window bottom.
          ShowPathbar = true;

          # Status bar: displays item counts and free storage at the window bottom.
          ShowStatusBar = true;

          # Desktop icons: permits items to be shown on the desktop.
          CreateDesktop = true;

          # External disks: hides external hard drives from the desktop.
          ShowExternalHardDrivesOnDesktop = false;

          # Internal disks: hides hard drives from the desktop.
          ShowHardDrivesOnDesktop = false;

          # Network servers: hides mounted servers from the desktop.
          ShowMountedServersOnDesktop = false;

          # Removable media: hides removable media from the desktop.
          ShowRemovableMediaOnDesktop = false;

          # Desktop folder sorting: keeps folders before files on the desktop.
          _FXSortFoldersFirstOnDesktop = true;

          # Relative dates: displays complete dates instead of relative dates in Finder.
          FXUseRelativeDates = false;

          # Grouping: groups Finder list entries by their name.
          FXArrangeGroupViewBy = "Name";
        };

        "com.apple.screencapture" = {
          # Filename dates: includes the capture date in screenshot filenames.
          include-date = true;

          # Screenshot format: saves captures as PNG files.
          type = "png";

          # Window shadow: removes shadows from captured windows.
          disable-shadow = true;

          # Floating thumbnail: shows the temporary thumbnail after a capture.
          show-thumbnail = true;

          # Screenshot location: saves captures to the iCloud Downloads folder.
          location = "${paths.darwin.icloud.docs}/Downloads";
        };

        # ==========================================================
        # CLOCK — com.apple.menuextra.clock
        # ==========================================================
        "com.apple.menuextra.clock" = {
          # Use digital clock (not analog)
          IsAnalog = false;

          # Show full date
          ShowDate = 2;

          # Hide AM/PM
          ShowAMPM = false;

          # Use 24-hour clock
          Show24Hour = true;

          # Do not show seconds
          ShowSeconds = false;

          # Show day of week
          ShowDayOfWeek = true;

          # Show day of month
          ShowDayOfMonth = true;
        };
      };

      # Control Center values are specific to this Mac rather than a
      # networked account's defaults.
      targets.darwin.currentHostDefaults."com.apple.controlcenter" = {
        # Sound control: hides the Sound control from the menu bar.
        Sound = false;

        # AirDrop control: hides the AirDrop control from the menu bar.
        AirDrop = false;

        # Display control: hides the Display control from the menu bar.
        Display = false;

        # Bluetooth control: hides the Bluetooth control from the menu bar.
        Bluetooth = false;

        # Now Playing control: hides Now Playing from the menu bar.
        NowPlaying = false;

        # Focus control: hides Focus Modes from the menu bar.
        FocusModes = false;

        # Battery percentage: shows the battery percentage in the menu bar.
        BatteryShowPercentage = true;
      };

      # ------------------------------------------------------------
      # Session environment
      # ------------------------------------------------------------

      home.sessionVariables = {
      };

      # ------------------------------------------------------------
      # Shared terminal features
      # ------------------------------------------------------------

      ven.features.terminal.nvim = {
        enable = true;
        neovide.enable = true;
      };

      ven.features.terminal.wezterm = {
        enable = true;
      };

      # ------------------------------------------------------------
      # Nix alias host
      # ------------------------------------------------------------

      # The flake host name differs from macOS's networking host name.
      ven.features.terminal.fish.nixProfile.flakeHost = "macbook";

      # ------------------------------------------------------------
      # Imports
      # ------------------------------------------------------------

      imports = [
        # Darwin-only Home Manager
        ../terminal

        # Shared Home Manager
        inputs.self.homeModules.shared.espanso
        inputs.self.homeModules.shared.environment
        inputs.self.homeModules.shared.services

        # Shared terminal modules
        inputs.self.homeModules.shared.terminal

        # Shared secrets
        ../../shared/home/secrets.nix
        ../../shared/home/sops.nix

        # Per-machine service settings
        ./services.nix
      ];
    };
  };
}
