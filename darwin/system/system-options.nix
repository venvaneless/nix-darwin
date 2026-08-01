# /Users/ven/.config/nix/nix-config/darwin/modules/system/system-options.nix
#
# =====================================================================
# SYSTEM OPTIONS: GLUE
# 
# Aggregates core macOS system UI modules:
# - Dock options
# - Finder options
# - Fonts
# - Trackpad options
#
# Holds ONLY nix-darwin system-level options.
# =====================================================================

{ ... }:

{
  # ****************************************************************
  # ------ GLOBAL SYSTEM UI OPTIONS ------ #
  # ****************************************************************
  system.defaults = {

  	# ********************************************************
    # ------ GLOBAL MENU BAR + NSGlobalDomain ------ #
    # ********************************************************
    NSGlobalDomain = {

      # Menu bar auto-hide (system-wide)
      _HIHideMenuBar = true;

    # ---------------------------------------------------------
    # ---- UI RESPONSIVENESS
   	# ---------------------------------------------------------

      # Disable most window animations
      NSAutomaticWindowAnimationsEnabled = false;

      # Speed up window resize animations
      NSWindowResizeTime = 0.001;
    };
   	# ---------------------------------------------------------

    
    # ********************************************************
    # ------ ACCESSIBILITY (UI EFFECTS) ------ #
    # ********************************************************
    universalaccess = {

      # Reduce transparency effects
      reduceTransparency = false;

      # Reduce motion / animations
      reduceMotion = false;
    };
  };
 	# ---------------------------------------------------------


  # ****************************************************************
  # --- POWER MANAGEMENT
  # ****************************************************************
  power.sleep = {

    # When plugged in
    # display  = 10;     # minutes
    # computer = 20;     # minutes
    # harddisk = "never";
  };
  # ****************************************************************


  # ****************************************************************
  # ---- MODULE IMPORTS
  # ****************************************************************
  imports = [
    ./dock-options.nix
    ./finder-options.nix
    ./fonts.nix
    ./keyboard.nix
    ./locale.nix
    ./mouse.nix
    ./screenshot-options.nix
    ./statusbar.nix
    ./trackpad.nix
    # ./wallpaper.nix
  ];
  # ****************************************************************
}
