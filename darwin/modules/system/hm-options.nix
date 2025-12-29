# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/hm-options.nix
#
# HOME MANAGER — MACOS OPTIONS (GLUE)
# ============================================================
# Aggregates Home Manager–only macOS defaults:
# - Locale / language / measurement units
# - Menu bar clock
# - User-session environment variables
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

      # ---- Preferred UI languages (order matters) ----
      AppleLanguages = [ "en" "de" "pl" ];

      # ---- Locale (controls formats like dates, numbers) ----
      AppleLocale = "en_DE";

      # ---- Measurement units ----
      AppleMeasurementUnits = "Centimeters";
    };
  };

  # ------------------------------------------------------------
  # HOME MANAGER — SESSION ENVIRONMENT
  # ------------------------------------------------------------
  home.sessionVariables = {

    # ----------------------------------------------------------
    # USER-SCOPED PATH OVERRIDES
    # ----------------------------------------------------------
    
    # ---- Espanso path overrides ----
    ESPANSO_CONFIG_DIR = "/Users/ven/ven-dots/user-data/apps/espanso/config";
    ESPANSO_DATA_DIR   = "/Users/ven/ven-dots/user-data/apps/espanso/data";
  };

  # ------------------------------------------------------------
  # MODULES
  # ------------------------------------------------------------
  imports = [
    ./clock.nix
  ];
}
