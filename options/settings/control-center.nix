# options/settings/control-center.nix
#
# =====================================================================
# OPTIONS: CONTROL CENTER MENU BAR ITEMS
#
# true shows an item, false hides it, null leaves it untouched.
# =====================================================================

{
  config,
  lib,
  platforms,
  ...
}:

let
  cfg = config.home.darwin.settings.controlCenter;

  # macOS visibility codes
  visibilityCode = show: if show then 18 else 24;

  items = {
    sound = "Sound";
    airDrop = "AirDrop";
    display = "Display";
    bluetooth = "Bluetooth";
    nowPlaying = "NowPlaying";
    focusModes = "FocusModes";
  };

  itemOption = name: lib.mkOption {
    type = lib.types.nullOr lib.types.bool;
    default = null;
    description = "Show ${name} in the menu bar.";
  };

  setItems = lib.filterAttrs (knob: _: cfg.${knob} != null) items;
in
{
  options.home.darwin.settings.controlCenter = lib.mapAttrs (_: itemOption) items;

  config = platforms.onlyOnDarwin {
    targets.darwin.currentHostDefaults."com.apple.controlcenter" =
      lib.mapAttrs' (knob: key: lib.nameValuePair key (visibilityCode cfg.${knob})) setItems;
  };
}
