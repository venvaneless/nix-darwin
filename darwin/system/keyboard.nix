# darwin/system/keyboard.nix
#
# =====================================================================
# KEYBOARD OPTIONS
# System-level keyboard and typing behavior.
#
# Covers:
# - Hardware key remapping
# - Function key behavior
# - Global text input behavior (non-layout)
#
# NOTE:
# These are system-wide settings managed by nix-darwin,
# not per-user Home Manager options.
# =====================================================================

{ config, lib, pkgs, ... }:

{

  # ****************************************************************
  # ------ HARDWARE KEYBOARD MAPPING ------ #
  # ****************************************************************
  system.keyboard = {
    # Custom key mapping
    enableKeyMapping = true;

    # Caps Lock behavior
    remapCapsLockToEscape  = false;
    remapCapsLockToControl = false;
  };
  # ****************************************************************

  
  # ****************************************************************
  # ------ GLOBAL KEYBOARD / TEXT INPUT BEHAVIOR ------ #
  # ****************************************************************
  system.defaults.NSGlobalDomain = {
  # ****************************************************************

 	# ---------------------------------------------------------
    # ---- FUNCTION KEYS

    # Use F1, F2, etc. as standard function keys
    # (media keys require holding Fn)
    "com.apple.keyboard.fnState" = true;
   	# ---------------------------------------------------------

    
   	# ---------------------------------------------------------
    # ---- TEXT INPUT BEHAVIOR

    # Automatic capitalization
    NSAutomaticCapitalizationEnabled = true;

    # Smart quotes
    NSAutomaticQuoteSubstitutionEnabled = true;

    # Smart dashes
    NSAutomaticDashSubstitutionEnabled = true;

    # Automatic period substitution
    NSAutomaticPeriodSubstitutionEnabled = false;

    # Automatic spell correction
    NSAutomaticSpellingCorrectionEnabled = false;
   	# ---------------------------------------------------------
  };
}
