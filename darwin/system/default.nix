# darwin/system/default.nix
#
# =====================================================================
# MACOS SYSTEM SETTINGS
#
# Consolidates the active nix-darwin system settings previously split by
# subject in this directory. Homebrew stays in ./homebrew.nix.
# =====================================================================

{
  lib,
  options,
  pkgs,
  ...
}:

let
  # Shared path definitions keep Dock entries aligned with their owners.
  helpers = import ../../options { inherit lib options pkgs; };
  inherit (helpers) paths;
in
{
  system.defaults = {
    # ===================================================================
    # GLOBAL UI AND ACCESSIBILITY SETTINGS
    # ===================================================================
    NSGlobalDomain = {
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

    universalaccess = {
      # Transparency: keeps macOS transparency effects enabled.
      reduceTransparency = false;

      # Motion: keeps macOS motion and animation effects enabled.
      reduceMotion = false;

      # Pointer size: sets the cursor to a larger-than-default size.
      mouseDriverCursorSize = 2.0;
    };

    # Mouse tracking speed: sets pointer movement speed for a physical mouse.
    ".GlobalPreferences"."com.apple.mouse.scaling" = 2.0;

    # ===================================================================
    # DOCK SETTINGS
    # ===================================================================
    dock = {
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

      # Persistent applications: pins these application bundles to the Dock.
      persistent-apps = [
        paths.darwin.applications.bundles.cider
        paths.darwin.applications.bundles.wezterm
        paths.darwin.applications.bundles.helium
        paths.darwin.applications.bundles.zed
        paths.darwin.applications.bundles.snippetsLab

        # The real signed app owns the running process, so pinning it keeps
        # the running-dot on this tile instead of creating a recent-app tile.
        paths.darwin.applications.bundles.chatgpt
      ];
    };

    # ===================================================================
    # FINDER SETTINGS
    # ===================================================================
    finder = {
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
    };

    # -------------------------------------------------------------------
    # FINDER RAW PREFERENCES
    # Settings not exposed by nix-darwin's typed Finder option.
    # -------------------------------------------------------------------
    CustomUserPreferences."com.apple.finder" = {
      # Relative dates: displays complete dates instead of relative dates in Finder.
      FXUseRelativeDates = false;

      # Grouping: groups Finder list entries by their name.
      FXArrangeGroupViewBy = "Name";
    };

    # ===================================================================
    # SCREENSHOT SETTINGS
    # ===================================================================
    screencapture = {
      # Filename dates: includes the capture date in screenshot filenames.
      include-date = true;

      # Screenshot format: saves captures as PNG files.
      type = "png";

      # Window shadow: removes shadows from captured windows.
      disable-shadow = true;

      # Floating thumbnail: shows the temporary thumbnail after a capture.
      show-thumbnail = true;

      # Screenshot location: saves captures to the iCloud Downloads folder.
      location = "/Users/ven/iCloudDocs/Downloads";
    };

    # ===================================================================
    # CONTROL CENTER SETTINGS
    # ===================================================================
    controlcenter = {
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

    # ===================================================================
    # TRACKPAD SETTINGS
    # ===================================================================
    trackpad = {
      # Haptic feedback: enables feedback for clicks and Force Touch.
      ActuateDetents = true;

      # Click sound: uses normal physical-click feedback.
      ActuationStrength = 1;

      # Tap to click: disables single-finger tap clicking.
      Clicking = false;

      # Drag lock: disables continuing a drag after lifting the finger.
      DragLock = false;

      # Tap to drag: enables drag gestures without physically clicking.
      Dragging = true;

      # Normal click pressure: uses medium pressure for physical clicks.
      FirstClickThreshold = 1;

      # Force Click: leaves Force Click enabled.
      ForceSuppressed = false;

      # Force Click pressure: uses medium pressure for Force Click.
      SecondClickThreshold = 1;

      # Corner secondary click: enables right click in the bottom-right corner.
      TrackpadCornerSecondaryClick = 2;

      # Two-finger secondary click: disables two-finger right clicking.
      TrackpadRightClick = false;

      # Three-finger drag: enables dragging windows with three fingers.
      TrackpadThreeFingerDrag = true;

      # Momentum scrolling: enables inertial scrolling.
      TrackpadMomentumScroll = true;

      # Smart Zoom: enables two-finger double-tap zoom.
      TrackpadTwoFingerDoubleTapGesture = true;

      # Pinch to zoom: disables pinch-to-zoom gestures.
      TrackpadPinch = false;

      # Rotation: disables two-finger rotation gestures.
      TrackpadRotate = false;

      # Full-screen app swipe: enables four-finger horizontal app switching.
      TrackpadFourFingerHorizSwipeGesture = 2;

      # Launchpad/Desktop gesture: enables the four-finger pinch gesture.
      TrackpadFourFingerPinchGesture = 2;

      # Mission Control gesture: enables four-finger vertical Mission Control.
      TrackpadFourFingerVertSwipeGesture = 2;

      # Page swipe: uses three-finger horizontal swipes between pages.
      TrackpadThreeFingerHorizSwipeGesture = 1;

      # Three-finger tap: disables Look Up and data-detector tapping.
      TrackpadThreeFingerTapGesture = 0;

      # App Exposé gesture: disables three-finger vertical App Exposé.
      TrackpadThreeFingerVertSwipeGesture = 0;

      # Notification Center: enables a two-finger right-edge swipe.
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
    };
  };

  # ===================================================================
  # KEYBOARD SETTINGS
  # ===================================================================
  system.keyboard = {
    # Custom key mapping: enables nix-darwin hardware key remapping.
    enableKeyMapping = true;

    # Caps Lock to Escape: keeps Caps Lock from acting as Escape.
    remapCapsLockToEscape = false;

    # Caps Lock to Control: keeps Caps Lock from acting as Control.
    remapCapsLockToControl = false;
  };

  # ===================================================================
  # POWER MANAGEMENT SETTINGS
  # ===================================================================
  # Power sleep: placeholder for future display, computer, and disk sleep rules.
  power.sleep = { };

  # ===================================================================
  # SYSTEM LOCALE SETTINGS
  # ===================================================================
  environment.variables = {
    # Default locale: uses US English with UTF-8 encoding.
    LANG = "en_US.UTF-8";

    # Locale override: applies the same locale to every locale category.
    LC_ALL = "en_US.UTF-8";
  };

  # ===================================================================
  # SYSTEM FONT SETTINGS
  # ===================================================================
  # System fonts: installs these Nerd Font families for all users.
  fonts.packages = [
    # JetBrains Mono: patched monospaced font for terminals and editors.
    pkgs.nerd-fonts.jetbrains-mono

    # Fira Code: patched monospaced font with programming ligatures.
    pkgs.nerd-fonts.fira-code

    # Meslo LG: patched monospaced font commonly used by shell prompts.
    pkgs.nerd-fonts.meslo-lg
  ];

  # ===================================================================
  # WALLPAPER (DISABLED)
  # ===================================================================
  # The previous wallpaper module was not imported. Keep it disabled so
  # this consolidation does not introduce activation-time behavior.
  #
  # system.activationScripts.setWallpaper.text = ''
  #   ...
  # '';
}
