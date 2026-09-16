# options/settings/trackpad.nix
#
# =====================================================================
# OPTIONS: TRACKPAD
#
# Readable knobs written to both the built-in and Bluetooth trackpad
# domains. null leaves a preference untouched.
# =====================================================================

{
  config,
  lib,
  platforms,
  ...
}:

let
  cfg = config.home.darwin.settings.trackpad;

  domains = [
    "com.apple.AppleMultitouchTrackpad"
    "com.apple.driver.AppleBluetoothMultitouch.trackpad"
  ];

  # ---- Trackpad codes
  pressureCodes = {
    "Light" = 0;
    "Medium" = 1;
    "Firm" = 2;
  };

  cornerCodes = {
    "Off" = 0;
    "Bottom Left" = 1;
    "Bottom Right" = 2;
  };

  threeFingerHorizontalCodes = {
    "Off" = 0;
    "Pages" = 1;
    "Full-Screen Apps" = 2;
  };

  # ---- Helpers
  nullOr = type: description: lib.mkOption {
    type = lib.types.nullOr type;
    default = null;
    inherit description;
  };

  enumOf = codes: lib.types.enum (lib.attrNames codes);

  set = value: attrs: lib.optionalAttrs (value != null) attrs;

  # Gestures stored as 0 when off and a fixed code when on
  gestureCode = on: enabled: if enabled then on else 0;

  gestures = cfg.gestures;

  preferences =
    set cfg.tapToClick { Clicking = cfg.tapToClick; }
    // set cfg.silentClicking { ActuationStrength = if cfg.silentClicking then 0 else 1; }
    // set cfg.clickPressure { FirstClickThreshold = pressureCodes.${cfg.clickPressure}; }
    // set cfg.forceClick { ForceSuppressed = !cfg.forceClick; }
    // set cfg.forceClickPressure { SecondClickThreshold = pressureCodes.${cfg.forceClickPressure}; }
    // set cfg.hapticFeedback { ActuateDetents = cfg.hapticFeedback; }
    // set cfg.twoFingerSecondaryClick { TrackpadRightClick = cfg.twoFingerSecondaryClick; }
    // set cfg.secondaryClickCorner { TrackpadCornerSecondaryClick = cornerCodes.${cfg.secondaryClickCorner}; }
    // set cfg.tapToDrag { Dragging = cfg.tapToDrag; }
    // set cfg.dragLock { DragLock = cfg.dragLock; }
    // set cfg.threeFingerDrag { TrackpadThreeFingerDrag = cfg.threeFingerDrag; }
    // set cfg.momentumScroll { TrackpadMomentumScroll = cfg.momentumScroll; }
    // set cfg.pinchZoom { TrackpadPinch = cfg.pinchZoom; }
    // set cfg.rotate { TrackpadRotate = cfg.rotate; }
    // set cfg.smartZoom { TrackpadTwoFingerDoubleTapGesture = cfg.smartZoom; }
    // set gestures.threeFingerHorizontal {
      TrackpadThreeFingerHorizSwipeGesture = threeFingerHorizontalCodes.${gestures.threeFingerHorizontal};
    }
    // set gestures.threeFingerVertical { TrackpadThreeFingerVertSwipeGesture = gestureCode 2 gestures.threeFingerVertical; }
    // set gestures.threeFingerTap { TrackpadThreeFingerTapGesture = gestureCode 2 gestures.threeFingerTap; }
    // set gestures.fourFingerHorizontal { TrackpadFourFingerHorizSwipeGesture = gestureCode 2 gestures.fourFingerHorizontal; }
    // set gestures.fourFingerVertical { TrackpadFourFingerVertSwipeGesture = gestureCode 2 gestures.fourFingerVertical; }
    // set gestures.fourFingerPinch { TrackpadFourFingerPinchGesture = gestureCode 2 gestures.fourFingerPinch; }
    // set gestures.twoFingersRightEdge {
      TrackpadTwoFingerFromRightEdgeSwipeGesture = gestureCode 3 gestures.twoFingersRightEdge;
    };
in
{
  options.home.darwin.settings.trackpad = {
    tapToClick = nullOr lib.types.bool "Tap to click.";
    silentClicking = nullOr lib.types.bool "Quieter clicks.";
    clickPressure = nullOr (enumOf pressureCodes) "Pressure needed for a normal click.";
    forceClick = nullOr lib.types.bool "Force click and haptic feedback.";
    forceClickPressure = nullOr (enumOf pressureCodes) "Pressure needed for a force click.";
    hapticFeedback = nullOr lib.types.bool "Haptic detents while force clicking.";
    twoFingerSecondaryClick = nullOr lib.types.bool "Secondary click with two fingers.";
    secondaryClickCorner = nullOr (enumOf cornerCodes) "Corner used for secondary click.";
    tapToDrag = nullOr lib.types.bool "Double-tap and drag.";
    dragLock = nullOr lib.types.bool "Keep dragging after lifting the finger.";
    threeFingerDrag = nullOr lib.types.bool "Drag with three fingers.";
    momentumScroll = nullOr lib.types.bool "Keep scrolling after the fingers lift.";
    pinchZoom = nullOr lib.types.bool "Zoom in or out by pinching.";
    rotate = nullOr lib.types.bool "Rotate with two fingers.";
    smartZoom = nullOr lib.types.bool "Zoom by double-tapping with two fingers.";

    gestures = {
      threeFingerHorizontal = nullOr (enumOf threeFingerHorizontalCodes) "Three-finger horizontal swipe.";
      threeFingerVertical = nullOr lib.types.bool "Three-finger vertical swipe for Mission Control.";
      threeFingerTap = nullOr lib.types.bool "Three-finger tap for Look Up.";
      fourFingerHorizontal = nullOr lib.types.bool "Four-finger swipe between full-screen apps.";
      fourFingerVertical = nullOr lib.types.bool "Four-finger swipe for Mission Control.";
      fourFingerPinch = nullOr lib.types.bool "Four-finger pinch for Launchpad and the desktop.";
      twoFingersRightEdge = nullOr lib.types.bool "Swipe left from the right edge for Notification Center.";
    };
  };

  config = platforms.onlyOnDarwin {
    targets.darwin.defaults = lib.genAttrs domains (_: preferences);
  };
}
