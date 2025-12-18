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
    # GLOBAL MENU BAR
    # ----------------------------------------------------------

    # Menu bar auto-hide (system-wide)
    NSGlobalDomain._HIHideMenuBar = true;

    # ----------------------------------------------------------
    # ACCESSIBILITY (UI EFFECTS)
    # ----------------------------------------------------------

    # Reduce transparency effects
    universalaccess.reduceTransparency = false;

    # Reduce motion / animations
    universalaccess.reduceMotion = false;
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
    ./screenshot-options.nix
    ./statusbar.nix
    ./trackpad.nix
  ];
}
