# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/trackpad.nix
#
# TRACKPAD OPTIONS
# ============================================================
# Trackpad defaults configured via nix-darwin.
# - Controls click behaviour, force click and haptics.
# - Controls scrolling, zoom, rotate and swipe gestures.
# - Encodes all current settings from macOS Trackpad + Accessibility.
# ============================================================
#
{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # TRACKPAD CORE SETTINGS
  # Click behaviour and gestures
  # ------------------------------------------------------------
  #
  system.defaults.trackpad = {

    # ------ CLICK SETTINGS ------ #

    # --- Haptic feedback
    # -----------------------------------------
    # ActuateDetents:
    #   true  = haptic feedback enabled
    #   false = haptic feedback disabled
    # -----------------------------------------
    ActuateDetents = true;

    # --- Silent clicking
    # -----------------------------------------
    # ActuationStrength:
    #   0 = enable Silent Click
    #   1 = disable Silent Click (normal click sound)
    # -----------------------------------------
    ActuationStrength = 1;

    # --- Tap to click
    # -----------------------------------------
    # Clicking:
    #   true  = tap with one finger = click
    #   false = tap does nothing (you must press)
    # -----------------------------------------
    Clicking = false;

    # --- Drag lock
    # -----------------------------------------
    # DragLock:
    #   true  = drag lock enabled (keeps item “grabbed” after drag)
    #   false = no drag lock
    # -----------------------------------------
    DragLock = false;

    # --- Tap to drag
    # -----------------------------------------
    # Dragging:
    #   true  = enables drag by tap
    # From 'Accessibility “Use trackpad for dragging”)'
    #   false = disabled
    # -----------------------------------------
    Dragging = true;

    # --- Click pressure (normal click)
    # -----------------------------------------
    # FirstClickThreshold:
    #   0 = light
    #   1 = medium
    #   2 = firm
    # -----------------------------------------
    FirstClickThreshold = 1;

    # --- Force click suppression
    # -----------------------------------------
    # ForceSuppressed:
    #   true  = force click disabled
    #   false = force click enabled
    # -----------------------------------------
    ForceSuppressed = false;

    # --- Force click pressure
    # -----------------------------------------
    # SecondClickThreshold:
    #   0 = light
    #   1 = medium
    #   2 = firm
    # -----------------------------------------
    SecondClickThreshold = 1;

    # --- Secondary click corner
    # -----------------------------------------
    # TrackpadCornerSecondaryClick:
    #   0 = disabled
    #   1 = bottom-left corner
    #   2 = bottom-right corner
    # -----------------------------------------
    TrackpadCornerSecondaryClick = 2;

    # --- Two-finger secondary click
    # -----------------------------------------
    # TrackpadRightClick:
    #   true  = two-finger tap/click is right click
    #   false = disabled (only corner secondary click works)
    # -----------------------------------------
    TrackpadRightClick = false;

    # ------ DISABLED ------ #
    # (none here – all click settings above are your active values)


    # ------ DRAG SETTINGS ------ #

    # --- Three-finger drag
    # -----------------------------------------
    # TrackpadThreeFingerDrag:
    #   true  = three-finger drag enabled
    #   false = disabled
    # -----------------------------------------
    TrackpadThreeFingerDrag = true;

    # ------ SCROLL SETTINGS ------ #

    # --- Inertia when scrolling
    # -----------------------------------------
    # TrackpadMomentumScroll:
    #   true  = scroll with inertia (“Use inertia when scrolling” ON)
    #   false = no inertia
    # -----------------------------------------
    TrackpadMomentumScroll = true;

    # ------ ZOOM / ROTATE ------ #

    # --- Smart zoom
    # -----------------------------------------
    # TrackpadTwoFingerDoubleTapGesture:
    #   true  = double-tap with two fingers = smart zoom
    #   false = disabled
    # -----------------------------------------
    TrackpadTwoFingerDoubleTapGesture = true;

    # --- Pinch to zoom
    # -----------------------------------------
    # TrackpadPinch:
    #   true  = pinch with two fingers to zoom
    #   false = disabled
    # -----------------------------------------
    TrackpadPinch = false;

    # --- Rotate with two fingers
    # -----------------------------------------
    # TrackpadRotate:
    #   true  = rotate gesture enabled
    #   false = disabled
    # -----------------------------------------
    TrackpadRotate = false;

  
    # ------ SWIPE GESTURES ------ #

    # --- Swipe between full-screen apps
    # -----------------------------------------
    # TrackpadFourFingerHorizSwipeGesture:
    #   0 = disabled
    #   2 = swipe between full-screen apps / desktops
    # -----------------------------------------
    TrackpadFourFingerHorizSwipeGesture = 2;

    # --- Launchpad + Desktop (pinch / spread)
    # -----------------------------------------
    # TrackpadFourFingerPinchGesture:
    #   0 = disabled
    #   2 = pinch = Launchpad, spread = Show Desktop
    # -----------------------------------------
    TrackpadFourFingerPinchGesture = 2;

    # --- Mission Control (four-finger swipe)
    # -----------------------------------------
    # TrackpadFourFingerVertSwipeGesture:
    #   0 = disabled
    #   2 = enabled (swipe up / down for Mission Control / App Exposé)
    # -----------------------------------------
    TrackpadFourFingerVertSwipeGesture = 2;

    # --- Swipe between pages
    # -----------------------------------------
    # TrackpadThreeFingerHorizSwipeGesture:
    #   0 = disabled
    #   1 = swipe between pages
    #   2 = swipe between full-screen apps
    # -----------------------------------------
    TrackpadThreeFingerHorizSwipeGesture = 1;

    # --- Look up & data detectors
    # -----------------------------------------
    # TrackpadThreeFingerTapGesture:
    #   0 = disabled (use Force Click with one finger instead)
    #   2 = three-finger tap = Look up & data detectors
    # -----------------------------------------
    TrackpadThreeFingerTapGesture = 0;

    # --- App Exposé (three-finger swipe) – OFF
    # -----------------------------------------
    # TrackpadThreeFingerVertSwipeGesture:
    #   0 = disabled
    #   2 = three-finger swipe for Mission Control / App Exposé
    # -----------------------------------------
    TrackpadThreeFingerVertSwipeGesture = 0;

    # --- Notification Center (two-finger from right edge)
    # -----------------------------------------
    # TrackpadTwoFingerFromRightEdgeSwipeGesture:
    #   0 = disabled
    #   3 = open Notification Center
    # -----------------------------------------
    TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
  };


  # ------------------------------------------------------------
  # GLOBAL SCROLL SETTINGS
  # Natural scrolling behaviour
  # ------------------------------------------------------------
  #
  # NSGlobalDomain key: "com.apple.swipescrolldirection"
  # true  = Natural scrolling (content tracks finger)
  # false = Traditional scrolling (Windows-style)
  #
  system.defaults.NSGlobalDomain = {
    "com.apple.swipescrolldirection" = true;
    _HIHideMenuBar = true;
  };
}
