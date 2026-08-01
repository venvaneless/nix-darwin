# darwin/home/hm-options.nix
#
# =====================================================================
# HOME MANAGER: MACOS OPTIONS
# 
# Aggregates Home Manager–only macOS defaults:
# - Locale / language / measurement units
# - Menu bar clock
# - User-session environment variables
#
# These options are user-scoped and not available in
# nix-darwin system modules.
# =====================================================================

{ ... }:

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
  };

  # ------------------------------------------------------------
  # MODULES
  # ------------------------------------------------------------
  imports = [
  
  	# --- User-level setting modules ---
    ./clock.nix
    
    # --- Home Manager services ---
    # ./espanso-launchd.nix
  ];
}
