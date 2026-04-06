# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/system-options.nix
#
# SYSTEM OPTIONS (GLUE)
# ============================================================
# Aggregates core macOS system UI modules:
# - Dock options
# - Finder options
# - Fonts
# - Trackpad options
#
# Holds ONLY nix-darwin system-level options.
# ============================================================

{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # GLOBAL SYSTEM UI OPTIONS (TYPED)
  # ------------------------------------------------------------
  system.defaults = {

    # ----------------------------------------------------------
    # GLOBAL MENU BAR + NSGlobalDomain DEFAULTS
    # ----------------------------------------------------------
    NSGlobalDomain = {

      # Menu bar auto-hide (system-wide)
      _HIHideMenuBar = true;

      # --------------------------------------------------------
      # UI RESPONSIVENESS
      # --------------------------------------------------------

      # Disable most window animations
      NSAutomaticWindowAnimationsEnabled = false;

      # Speed up window resize animations
      NSWindowResizeTime = 0.001;
    };

    # ----------------------------------------------------------
    # ACCESSIBILITY (UI EFFECTS)
    # ----------------------------------------------------------
    universalaccess = {

      # Reduce transparency effects
      reduceTransparency = false;

      # Reduce motion / animations
      reduceMotion = false;
    };
  };

  # ------------------------------------------------------------
  # POWER MANAGEMENT
  # ------------------------------------------------------------
  power.sleep = {

    # When plugged in
    display  = 10;     # minutes
    computer = 20;     # minutes
    harddisk = "never";
  };

  # ------------------------------------------------------------
  # MODULE IMPORTS
  # ------------------------------------------------------------
  imports = [
    ./dock-options.nix
    ./finder-options-noscript.nix
    ./fonts.nix
    ./keyboard.nix
    ./locale.nix
    ./mouse.nix
    ./screenshot-options.nix
    ./statusbar.nix
    ./trackpad.nix
    ./wallpaper.nix
  ];
}
