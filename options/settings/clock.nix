# options/settings/clock.nix
#
# =====================================================================
# OPTIONS: MENU BAR CLOCK
#
# Readable knobs translated into com.apple.menuextra.clock preferences.
# null leaves a preference untouched.
# =====================================================================

{
  config,
  lib,
  platforms,
  ...
}:

let
  cfg = config.home.darwin.settings.clock;

  showDateCodes = {
    "When Space Allows" = 0;
    "Always" = 1;
    "Never" = 2;
  };

  nullOr = type: description: lib.mkOption {
    type = lib.types.nullOr type;
    default = null;
    inherit description;
  };

  set = value: attrs: lib.optionalAttrs (value != null) attrs;
in
{
  options.home.darwin.settings.clock = {
    analog = nullOr lib.types.bool "Analog clock instead of digital.";
    showDate = nullOr (lib.types.enum (lib.attrNames showDateCodes)) "When the date is shown.";
    dayOfWeek = nullOr lib.types.bool "Show the day of the week.";
    dayOfMonth = nullOr lib.types.bool "Show the day of the month.";
    hour24 = nullOr lib.types.bool "Use a 24-hour clock.";
    amPm = nullOr lib.types.bool "Show AM/PM.";
    seconds = nullOr lib.types.bool "Show seconds.";
  };

  config = platforms.onlyOnDarwin {
    targets.darwin.defaults."com.apple.menuextra.clock" =
      set cfg.analog { IsAnalog = cfg.analog; }
      // set cfg.showDate { ShowDate = showDateCodes.${cfg.showDate}; }
      // set cfg.dayOfWeek { ShowDayOfWeek = cfg.dayOfWeek; }
      // set cfg.dayOfMonth { ShowDayOfMonth = cfg.dayOfMonth; }
      // set cfg.hour24 { Show24Hour = cfg.hour24; }
      // set cfg.amPm { ShowAMPM = cfg.amPm; }
      // set cfg.seconds { ShowSeconds = cfg.seconds; };
  };
}
