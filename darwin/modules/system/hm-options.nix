# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/hm-options.nix
#
# HOME MANAGER — MACOS OPTIONS (GLUE)
# ============================================================
# Aggregates Home Manager–only macOS defaults:
# - Locale / language / measurement units
# - Menu bar clock
#
# These options are user-scoped and not available in
# nix-darwin system modules.
# ============================================================

{ config, lib, ... }:

{
  # ------------------------------------------------------------
  # HOME MANAGER — RAW MACOS DEFAULTS
  # ------------------------------------------------------------
  targets.darwin.defaults = {

    # ==========================================================
    # NSGlobalDomain — LOCALE & MEASUREMENT
    # ==========================================================
    NSGlobalDomain = {

      # Preferred UI languages (order matters)
      AppleLanguages = [ "en" "de" "pl" ];

      # Locale (controls formats like dates, numbers)
      AppleLocale = "en_DE";

      # Measurement units
      AppleMeasurementUnits = "Centimeters";
    };
  };

  # ------------------------------------------------------------
  # FEATURE MODULES
  # ------------------------------------------------------------
  imports = [
    ./clock.nix
  ];
}
