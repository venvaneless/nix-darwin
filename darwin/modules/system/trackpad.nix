# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/trackpad.nix
#
# TRACKPAD OPTIONS
# ============================================================
# Trackpad defaults configured via nix-darwin.
#
# Covers:
# - Click and tap behavior
# - Force click and haptics
# - Dragging
# - Scrolling, zooming, rotation
# - System gestures
# ============================================================

{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # TRACKPAD CORE SETTINGS
  # ------------------------------------------------------------
  system.defaults.trackpad = {

    # --- Haptic feedback --- #
    # ----------------------------------------------------------
    # Enables or disables haptic feedback when clicking or force-clicking
    # the trackpad.
    #
    # ActuateDetents:
    #   true  = haptic feedback enabled
    #   false = haptic feedback disabled
    # ----------------------------------------------------------
    ActuateDetents = true;

    # --- Silent clicking --- #
    # ----------------------------------------------------------
    # Controls whether a physical click sound is produced.
    #
    # ActuationStrength:
    #   0 = silent click (no sound)
    #   1 = normal click sound
    # ----------------------------------------------------------
    ActuationStrength = 1;

    # --- Tap to click --- #
    # ----------------------------------------------------------
    # Allows tapping the trackpad surface to register as a click.
    #
    # Clicking:
    #   true  = tap registers as click
    #   false = tap does nothing
    # ----------------------------------------------------------
    Clicking = false;

    # --- Drag lock --- #
    # ----------------------------------------------------------
    # Keeps an item grabbed after lifting the finger during a drag
    # until another click/tap occurs.
    #
    # DragLock:
    #   true  = drag lock enabled
    #   false = drag lock disabled
    # ----------------------------------------------------------
    DragLock = false;

    # --- Tap to drag (Accessibility) --- #
    # ----------------------------------------------------------
    # Enables dragging items using tap gestures instead of physical clicks.
    #
    # Dragging:
    #   true  = tap-drag enabled
    #   false = tap-drag disabled
    # ----------------------------------------------------------
    Dragging = true;

    # --- Click pressure (normal click) --- #
    # ----------------------------------------------------------
    # Determines how hard you must press for a normal click.
    #
    # FirstClickThreshold:
    #   0 = light pressure
    #   1 = medium pressure
    #   2 = firm pressure
    # ----------------------------------------------------------
    FirstClickThreshold = 1;

    # --- Force click enable / disable --- #
    # ----------------------------------------------------------
    # Controls whether force-click actions are available.
    #
    # ForceSuppressed:
    #   true  = force click disabled
    #   false = force click enabled
    # ----------------------------------------------------------
    ForceSuppressed = false;

    # --- Force click pressure --- #
    # ----------------------------------------------------------
    # Determines how hard you must press to trigger a force click.
    #
    # SecondClickThreshold:
    #   0 = light pressure
    #   1 = medium pressure
    #   2 = firm pressure
    # ----------------------------------------------------------
    SecondClickThreshold = 1;

    # --- Secondary click corner --- #
    # ----------------------------------------------------------
    # Enables right-click using a specific trackpad corner.
    #
    # TrackpadCornerSecondaryClick:
    #   0 = disabled
    #   1 = bottom-left corner
    #   2 = bottom-right corner
    # ----------------------------------------------------------
    TrackpadCornerSecondaryClick = 2;

    # --- Two-finger right click --- #
    # ----------------------------------------------------------
    # Enables right-click using a two-finger tap or click.
    #
    # TrackpadRightClick:
    #   true  = two-finger right click enabled
    #   false = disabled
    # ----------------------------------------------------------
    TrackpadRightClick = false;

    # --- Three-finger drag --- #
    # ----------------------------------------------------------
    # Allows dragging windows by swiping with three fingers.
    #
    # TrackpadThreeFingerDrag:
    #   true  = enabled
    #   false = disabled
    # ----------------------------------------------------------
    TrackpadThreeFingerDrag = true;

    # --- Scroll inertia --- #
    # ----------------------------------------------------------
    # Enables momentum (inertia) when scrolling.
    #
    # TrackpadMomentumScroll:
    #   true  = inertia enabled
    #   false = inertia disabled
    # ----------------------------------------------------------
    TrackpadMomentumScroll = true;

    # --- Smart zoom --- #
    # ----------------------------------------------------------
    # Double-tap with two fingers to zoom in/out.
    #
    # TrackpadTwoFingerDoubleTapGesture:
    #   true  = enabled
    #   false = disabled
    # ----------------------------------------------------------
    TrackpadTwoFingerDoubleTapGesture = true;

    # --- Pinch to zoom --- #
    # ----------------------------------------------------------
    # Zoom content by pinching with two fingers.
    #
    # TrackpadPinch:
    #   true  = enabled
    #   false = disabled
    # ----------------------------------------------------------
    TrackpadPinch = false;

    # --- Rotate --- #
    # ----------------------------------------------------------
    # Rotate content using a two-finger twist gesture.
    #
    # TrackpadRotate:
    #   true  = enabled
    #   false = disabled
    # ----------------------------------------------------------
    TrackpadRotate = false;

    # --- Swipe between full-screen apps --- #
    # ----------------------------------------------------------
    # Horizontal swipe gesture using four fingers.
    #
    # TrackpadFourFingerHorizSwipeGesture:
    #   0 = disabled
    #   2 = enabled (switch between full-screen apps / Spaces)
    # ----------------------------------------------------------
    TrackpadFourFingerHorizSwipeGesture = 2;

    # --- Launchpad / Show Desktop --- #
    # ----------------------------------------------------------
    # Pinch and spread gestures using four fingers.
    #
    # TrackpadFourFingerPinchGesture:
    #   0 = disabled
    #   2 = enabled (Launchpad / Show Desktop)
    # ----------------------------------------------------------
    TrackpadFourFingerPinchGesture = 2;

    # --- Mission Control / App Exposé --- #
    # ----------------------------------------------------------
    # Vertical swipe using four fingers.
    #
    # TrackpadFourFingerVertSwipeGesture:
    #   0 = disabled
    #   2 = enabled
    # ----------------------------------------------------------
    TrackpadFourFingerVertSwipeGesture = 2;

    # --- Swipe between pages --- #
    # ----------------------------------------------------------
    # Horizontal swipe using three fingers.
    #
    # TrackpadThreeFingerHorizSwipeGesture:
    #   0 = disabled
    #   1 = swipe between pages
    #   2 = swipe between full-screen apps
    # ----------------------------------------------------------
    TrackpadThreeFingerHorizSwipeGesture = 1;

    # --- Look up & data detectors --- #
    # ----------------------------------------------------------
    # Three-finger tap gesture.
    #
    # TrackpadThreeFingerTapGesture:
    #   0 = disabled
    #   2 = enabled (Look up / data detectors)
    # ----------------------------------------------------------
    TrackpadThreeFingerTapGesture = 0;

    # --- App Exposé (three-finger swipe) --- #
    # ----------------------------------------------------------
    # Vertical swipe using three fingers.
    #
    # TrackpadThreeFingerVertSwipeGesture:
    #   0 = disabled
    #   2 = enabled
    # ----------------------------------------------------------
    TrackpadThreeFingerVertSwipeGesture = 0;

    # --- Notification Center --- #
    # ----------------------------------------------------------
    # Swipe from the right edge using two fingers.
    #
    # TrackpadTwoFingerFromRightEdgeSwipeGesture:
    #   0 = disabled
    #   3 = open Notification Center
    # ----------------------------------------------------------
    TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
  };

  # ------------------------------------------------------------
  # NSGlobalDomain — TRACKPAD TAP BEHAVIOR
  # ------------------------------------------------------------
  system.defaults.NSGlobalDomain = {

    # --- Tap behavior --- #
    # ----------------------------------------------------------
    # Global tap-to-click behavior used by the trackpad.
    #
    # com.apple.mouse.tapBehavior:
    #   null = system default
    #   0    = disabled
    #   1    = enabled
    # ----------------------------------------------------------
    "com.apple.mouse.tapBehavior" = null;
  };
}
