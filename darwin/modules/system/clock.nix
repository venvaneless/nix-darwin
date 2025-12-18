# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/clock.nix
#
# MENU BAR CLOCK
# ============================================================
# User-level configuration of the macOS menu bar clock.
# Implemented via Home Manager's darwin defaults target.
# ============================================================

{ config, lib, ... }:

{
  targets.darwin.defaults = {

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
}
