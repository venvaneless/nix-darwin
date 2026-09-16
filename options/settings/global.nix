# options/settings/global.nix
#
# =====================================================================
# OPTIONS: GLOBAL MACOS PREFERENCES
#
# Readable knobs translated into NSGlobalDomain preferences.
# null leaves a preference untouched.
# =====================================================================

{
  config,
  lib,
  platforms,
  ...
}:

let
  cfg = config.home.darwin.settings.global;

  nullOr = type: description: lib.mkOption {
    type = lib.types.nullOr type;
    default = null;
    inherit description;
  };

  setIf = value: attrs: lib.optionalAttrs (value != null) attrs;
in
{
  options.home.darwin.settings.global = {
    darkMode = nullOr lib.types.bool "Use Dark appearance; false switches to Light.";
    naturalScrolling = nullOr lib.types.bool "Scroll content in the direction of finger movement.";
    pressAndHold = nullOr lib.types.bool "Show accent popups when holding a key instead of repeating it.";
    keyRepeat = nullOr lib.types.ints.positive "Key repeat interval in 15 ms steps; lower is faster.";
    initialKeyRepeat = nullOr lib.types.ints.positive "Delay before key repeat in 15 ms steps; lower is shorter.";
    beepVolume = nullOr (lib.types.ints.between 0 100) "Alert sound volume in percent.";
    beepFeedback = nullOr lib.types.bool "Play feedback when the volume is changed.";
  };

  config = platforms.onlyOnDarwin (lib.mkMerge [
    {
      targets.darwin.defaults.NSGlobalDomain =
        setIf cfg.darkMode (lib.optionalAttrs cfg.darkMode { AppleInterfaceStyle = "Dark"; })
        // setIf cfg.naturalScrolling { "com.apple.swipescrolldirection" = cfg.naturalScrolling; }
        // setIf cfg.pressAndHold { ApplePressAndHoldEnabled = cfg.pressAndHold; }
        // setIf cfg.keyRepeat { KeyRepeat = cfg.keyRepeat; }
        // setIf cfg.initialKeyRepeat { InitialKeyRepeat = cfg.initialKeyRepeat; }
        // setIf cfg.beepVolume { "com.apple.sound.beep.volume" = cfg.beepVolume / 100.0; }
        // setIf cfg.beepFeedback { "com.apple.sound.beep.feedback" = if cfg.beepFeedback then 1 else 0; };
    }

    # Light appearance is the absence of AppleInterfaceStyle.
    (lib.mkIf (cfg.darkMode == false) {
      home.activation.lightAppearance = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run /usr/bin/defaults delete -g AppleInterfaceStyle 2>/dev/null || true
      '';
    })
  ]);
}
