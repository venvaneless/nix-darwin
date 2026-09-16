# darwin/home/default.nix
#
# =====================================================================
# DARWIN: HOME MANAGER (INTEGRATED)
# =====================================================================
{
  inputs,
  paths,
  pkgs,
  settingsOptions,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
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
      # Darwin Home Manager defaults
      # ------------------------------------------------------------

      home.darwin.settings.global = {
        # Appearance: uses Dark mode; false switches to Light.
        darkMode = true;

        # Scroll direction: uses traditional rather than natural scrolling.
        naturalScrolling = false;

        # Press and hold: repeats keys instead of showing accent popups.
        pressAndHold = false;

        # Key repeat speed: 15 ms steps; 2 = 30 ms (macOS fastest slider is 2).
        keyRepeat = 2;

        # Key repeat delay: 15 ms steps; 15 = 225 ms (macOS shortest slider is 15).
        initialKeyRepeat = 15;

        # Alert volume: mutes the alert sound; 0–100 percent.
        beepVolume = 0;

        # Volume feedback: no sound when changing the volume.
        beepFeedback = false;
      };

      home.darwin.settings.trackpad = {
        # Tap to click: disabled; clicks need a physical press.
        tapToClick = false;

        # Silent clicking: keeps the normal click sound.
        silentClicking = false;

        # Click pressure: Values: "Light", "Medium", "Firm".
        clickPressure = "Medium";

        # Force click: enabled.
        forceClick = true;

        # Force click pressure: Values: "Light", "Medium", "Firm".
        forceClickPressure = "Medium";

        # Haptic detents: enabled while force clicking.
        hapticFeedback = true;

        # Two-finger secondary click: disabled.
        twoFingerSecondaryClick = false;

        # Secondary click corner: Values: "Off", "Bottom Left", "Bottom Right".
        secondaryClickCorner = "Bottom Right";

        # Tap to drag: double-tap and drag is enabled.
        tapToDrag = true;

        # Drag lock: stops dragging when the finger lifts.
        dragLock = false;

        # Three-finger drag: enabled.
        threeFingerDrag = true;

        # Momentum scrolling: enabled.
        momentumScroll = true;

        # Pinch to zoom: disabled.
        pinchZoom = false;

        # Rotate: disabled.
        rotate = false;

        # Smart zoom: two-finger double-tap zoom is enabled.
        smartZoom = true;

        gestures = {
          # Three-finger horizontal swipe: Values: "Off", "Pages", "Full-Screen Apps".
          threeFingerHorizontal = "Pages";

          # Three-finger vertical swipe: disabled.
          threeFingerVertical = false;

          # Three-finger tap (Look Up): disabled.
          threeFingerTap = false;

          # Four-finger horizontal swipe: switches full-screen apps.
          fourFingerHorizontal = true;

          # Four-finger vertical swipe: opens Mission Control.
          fourFingerVertical = true;

          # Four-finger pinch: opens Launchpad and shows the desktop.
          fourFingerPinch = true;

          # Right-edge swipe: opens Notification Center.
          twoFingersRightEdge = true;
        };
      };

      home.darwin.settings.clock = {
        # Clock style: digital instead of analog.
        analog = false;

        # Date: Values: "When Space Allows", "Always", "Never".
        showDate = "When Space Allows";

        # Day of week: shown.
        dayOfWeek = true;

        # Day of month: shown.
        dayOfMonth = true;

        # 24-hour clock: enabled.
        hour24 = true;

        # AM/PM: hidden.
        amPm = false;

        # Seconds: hidden.
        seconds = false;
      };

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

      };

      home.darwin.settings.finder = {
        # New window target: opens new windows and tabs at a custom location.
        # Values: "Computer", "OS volume", "Home", "Desktop", "Documents",
        # "Recents", "iCloud Drive", "Other" (uses newWindowTargetPath).
        newWindowTarget = "Other";

        # New window location: uses the standard macOS Downloads folder.
        newWindowTargetPath = paths.darwin.home.downloads;

        # Hidden files: shows files and folders normally hidden by Finder.
        showHidden = true;

        # Empty Trash: disables automatic deletion of Trash items after 30 days.
        removeOldTrash = false;

        # Preferred view: uses List view for newly opened Finder windows.
        # Values: "Icon", "List", "Column", "Gallery".
        viewStyle = "List";

        # Folder sorting: keeps folders before files in Finder windows.
        sortFoldersFirst = true;

        # Search scope: searches the current folder by default.
        # Values: "This Mac", "Current Folder", "Previous Scope".
        searchScope = "Current Folder";

        # File extensions: always displays filename extensions.
        showExtensions = true;

        # Extension warnings: disables warnings when changing file extensions.
        extensionChangeWarning = false;

        # Path bar: displays the current folder hierarchy at the window bottom.
        pathBar = true;

        # Status bar: displays item counts and free storage at the window bottom.
        statusBar = true;

        # Relative dates: displays complete dates instead of relative dates.
        relativeDates = false;

        # Grouping: groups Finder window entries by their name.
        # Values: "None", "Name", "Application", "Kind", "Date Last Opened",
        # "Date Added", "Date Modified", "Date Created", "Size", "Tags".
        arrangeGroupsView = "Name";

        desktop = {
          # Desktop icons: permits items to be shown on the desktop.
          showIcons = true;

          # External disks: hides external hard drives from the desktop.
          iconsExHDD = false;

          # Internal disks: hides hard drives from the desktop.
          iconsHDD = false;

          # Network servers: hides mounted servers from the desktop.
          iconsServers = false;

          # Removable media: hides removable media from the desktop.
          iconsRemovable = false;

          # Folder sorting: keeps folders before files on the desktop.
          sortFoldersFirst = true;
        };
      };

      targets.darwin.defaults = {
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
      };

      # Control Center values are specific to this Mac rather than a
      # networked account's defaults.
      home.darwin.settings.controlCenter = {
        # Sound control: hides the Sound control from the menu bar.
        sound = false;

        # AirDrop control: hides the AirDrop control from the menu bar.
        airDrop = false;

        # Display control: hides the Display control from the menu bar.
        display = false;

        # Bluetooth control: hides the Bluetooth control from the menu bar.
        bluetooth = false;

        # Now Playing control: hides Now Playing from the menu bar.
        nowPlaying = false;

        # Focus control: hides Focus Modes from the menu bar.
        focusModes = false;
      };

      targets.darwin.currentHostDefaults."com.apple.controlcenter" = {
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

      home.shared.terminal.nvim = {
        enable = true;
        neovide.enable = true;
      };

      home.shared.terminal.wezterm = {
        enable = true;
      };

      # ------------------------------------------------------------
      # Nix alias host
      # ------------------------------------------------------------

      # The flake host name differs from macOS's networking host name.
      home.shared.terminal.fish.nixProfile.flakeHost = "macbook";

      # ------------------------------------------------------------
      # Imports
      # ------------------------------------------------------------

      imports = [
        # Darwin-only Home Manager
        ../terminal

        # The independent Obsidian command is declared and configured only
        # for the MacBook; portable terminal hosts do not import it.
        ../../options/obsidian/default.nix
        ../../shared/terminal/commands/obsidian.nix

        # Readable knobs for macOS preferences stored as codes
        settingsOptions

        # Shared Home Manager
        inputs.self.homeModules."shared.home"

        # Shared secrets
        ../../shared/home/secrets.nix
        ../../shared/home/sops.nix

        # Per-machine service settings
        ./services.nix
      ];
    };
  };
}
