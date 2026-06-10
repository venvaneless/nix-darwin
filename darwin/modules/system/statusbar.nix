# /Users/ven/.config/nix/nix-config/darwin/modules/system/statusbar.nix
#
# STATUS BAR / CONTROL CENTER
# ============================================================
# Controls visibility of Apple-provided Control Center items.
#
# IMPORTANT:
# - Ordering is NOT controllable
# - Some items may still appear due to macOS restrictions
# ============================================================

{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # CONTROL CENTER ITEMS
  # ------------------------------------------------------------
  system.defaults.controlcenter = {

    # Hide Control Center modules from menu bar
    Sound       = false;
    AirDrop     = false;
    Display     = false;
    Bluetooth   = false;
    NowPlaying  = false;
    FocusModes  = false;

    # Battery percentage (explicitly enabled)
    BatteryShowPercentage = true;
  };
}
