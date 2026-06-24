# /Users/ven/.config/nix/nix-config/darwin/modules/system/trackpad.nix
#
# =====================================================================
# TRACKPAD OPTIONS
# 
# Trackpad defaults configured via nix-darwin.
#
# Covers:
# - Click and tap behavior
# - Force click and haptics
# - Dragging
# - Scrolling, zooming, rotation
# - System gestures
# =====================================================================

{ config, lib, pkgs, ... }:

{
	# ---------------------------------------------------------------
  # ------ TRACKPAD CORE SETTINGS ------ #
  # ---------------------------------------------------------------
  system.defaults.trackpad = {

 		# ********************************************************
    # ---- HAPTIC FEEDBACK
    # 
    # Enables or disables haptic feedback when clicking or force-clicking
    # the trackpad.
    #
    # ActuateDetents:
    #   true  = haptic feedback enabled
    #   false = haptic feedback disabled
    # ************************************
    ActuateDetents = true;
    # ********************************************************

    # ********************************************************
    # --- ACCESSIBILITY: SILENT CLICKING
    # Controls whether a physical click sound is produced
    #
    # ActuationStrength:
    #   0 = silent click (no sound)
    #   1 = normal click sound
    # ************************************
    ActuationStrength = 1;
    # ********************************************************

    # ********************************************************
    # --- ACCESSIBILITY: TAP TO CLICK
    # 
    # Allows tapping the trackpad surface to register as a click.
    #
    # Clicking:
    #   true  = tap registers as click
    #   false = tap does nothing
    # ************************************
    Clicking = false;
    # ********************************************************

    # ********************************************************
    # --- ACCESSIBILITY: DRAG LOCK
    # 
    # Keeps an item grabbed after lifting the finger during a drag
    # until another click/tap occurs.
    #
    # DragLock:
    #   true  = drag lock enabled
    #   false = drag lock disabled
    # ************************************
    DragLock = false;
    # ********************************************************

    # ********************************************************
    # --- ACCESSIBILITY: TAP TO DRAG
    # 
    # Enables dragging items using tap gestures instead of physical clicks.
    #
    # Dragging:
    #   true  = tap-drag enabled
    #   false = tap-drag disabled
    # ************************************
    Dragging = true;
    # ********************************************************

    # ********************************************************
    # --- ACCESSIBILITY: CLICK PRESSURE
    # 
    # Determines how hard you must press for a normal click.
    #
    # FirstClickThreshold:
    #   0 = light pressure
    #   1 = medium pressure
    #   2 = firm pressure
    # ************************************
    FirstClickThreshold = 1;
    # ********************************************************

    # ********************************************************
    # --- ACCESSIBILITY: FORCE CLICK TOGGLE
    # 
    # Controls whether force-click actions are available.
    #
    # ForceSuppressed:
    #   true  = force click disabled
    #   false = force click enabled
    # ************************************
    ForceSuppressed = false;
    # ********************************************************

    # ********************************************************
    # --- ACCESSIBILITY: FORCE CLICK PRESSURE
    # 
    # Determines how hard you must press to trigger a force click.
    #
    # SecondClickThreshold:
    #   0 = light pressure
    #   1 = medium pressure
    #   2 = firm pressure
    # ************************************
    SecondClickThreshold = 1;
    # ********************************************************

    # ********************************************************
    # --- SECONDARY CLICK: TOGGLE RIGHT CLICK
    # 
    # Enables right-click using a specific trackpad corner.
    #
    # TrackpadCornerSecondaryClick:
    #   0 = disabled
    #   1 = bottom-left corner
    #   2 = bottom-right corner
    # ************************************
    TrackpadCornerSecondaryClick = 2;
    # ********************************************************

    # ********************************************************
    # --- TWO-FINGER RIGHT CLICK
    # 
    # Enables right-click using a two-finger tap or click.
    #
    # TrackpadRightClick:
    #   true  = two-finger right click enabled
    #   false = disabled
    # ************************************
    TrackpadRightClick = false;
    # ********************************************************

    # ********************************************************
    # --- THREE-FINGER DRAG
    # 
    # Allows dragging windows by swiping with three fingers.
    #
    # TrackpadThreeFingerDrag:
    #   true  = enabled
    #   false = disabled
    # ************************************
    TrackpadThreeFingerDrag = true;
    # ********************************************************

    # ********************************************************
    # --- SCROLL INTERTIA
    # 
    # Enables momentum (inertia) when scrolling.
    #
    # TrackpadMomentumScroll:
    #   true  = inertia enabled
    #   false = inertia disabled
    # ************************************
    TrackpadMomentumScroll = true;
    # ********************************************************

    # ********************************************************
    # --- SMART ZOOM
    # 
    # Double-tap with two fingers to zoom in/out.
    #
    # TrackpadTwoFingerDoubleTapGesture:
    #   true  = enabled
    #   false = disabled
    # ************************************
    TrackpadTwoFingerDoubleTapGesture = true;

    # ********************************************************
    # --- PINCH-TO-ZOOM
    # 
    # Zoom content by pinching with two fingers.
    #
    # TrackpadPinch:
    #   true  = enabled
    #   false = disabled
    # ************************************
    TrackpadPinch = false;
    # ********************************************************

    # ********************************************************
    # --- ROTATE
    # 
    # Rotate content using a two-finger twist gesture.
    #
    # TrackpadRotate:
    #   true  = enabled
    #   false = disabled
    # ************************************
    TrackpadRotate = false;
    # ********************************************************

    # ********************************************************
    # --- SWIPE BETWEEN FULL-SCREEN APPS
    # 
    # Horizontal swipe gesture using four fingers.
    #
    # TrackpadFourFingerHorizSwipeGesture:
    #   0 = disabled
    #   2 = enabled (switch between full-screen apps / Spaces)
    # ************************************
    TrackpadFourFingerHorizSwipeGesture = 2;
    # ********************************************************

    # ********************************************************
    # --- LAUNCHPAD / SHOW DESKTOP: TOGGLE
    # 
    # Pinch and spread gestures using four fingers.
    #
    # TrackpadFourFingerPinchGesture:
    #   0 = disabled
    #   2 = enabled (Launchpad / Show Desktop)
    # ************************************
    TrackpadFourFingerPinchGesture = 2;
    # ********************************************************

    # ********************************************************
    # --- MISSION CONTROL / APP EXPOSÉ
    # 
    # Vertical swipe using four fingers.
    #
    # TrackpadFourFingerVertSwipeGesture:
    #   0 = disabled
    #   2 = enabled
    # ************************************
    TrackpadFourFingerVertSwipeGesture = 2;
    # ********************************************************

    # ********************************************************
    # --- SWIPE BETWEEN PAGES
    # 
    # Horizontal swipe using three fingers.
    #
    # TrackpadThreeFingerHorizSwipeGesture:
    #   0 = disabled
    #   1 = swipe between pages
    #   2 = swipe between full-screen apps
    # ************************************
    TrackpadThreeFingerHorizSwipeGesture = 1;
    # ********************************************************

    # ********************************************************
    # --- THREE-FINGER TAP GESTURE: TOGGLE
    #
    # TrackpadThreeFingerTapGesture:
    #   0 = disabled
    #   2 = enabled (Look up / data detectors)
    # ************************************
    TrackpadThreeFingerTapGesture = 0;
    # ********************************************************

    # ********************************************************
    # --- THREE FINGER VERTICAL SWIPE: APP EXPOSÉ
    #
    # TrackpadThreeFingerVertSwipeGesture:
    #   0 = disabled
    #   2 = enabled
    # ************************************
    TrackpadThreeFingerVertSwipeGesture = 0;
    # ********************************************************

    # ********************************************************
    # --- NOTIFICATION CENTER
    # 
    # Swipe from the right edge using two fingers.
    #
    # TrackpadTwoFingerFromRightEdgeSwipeGesture:
    #   0 = disabled
    #   3 = open Notification Center
    # ************************************
    TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
  };
  # ********************************************************

  # ---------------------------------------------------------------
  # ------ NSGlobalDomain — TRACKPAD TAP BEHAVIOR ------ #
  # ---------------------------------------------------------------
  system.defaults.NSGlobalDomain = {

  	# ********************************************************
    # --- Tap behavior --- #
    # 
    # Global tap-to-click behavior used by the trackpad.
    #
    # com.apple.mouse.tapBehavior:
    #   null = system default
    #   0    = disabled
    #   1    = enabled
    # ************************************
    "com.apple.mouse.tapBehavior" = null;
  };
}
