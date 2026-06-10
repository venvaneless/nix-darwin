# /Users/ven/.config/nix/nix-config/darwin/modules/system/mouse.nix
#
# MOUSE & POINTER SETTINGS
# ============================================================
# System-wide mouse and scrolling behavior.
#
# Covers:
# - Cursor size
# - Mouse speed
# - Scrolling direction
#
# Uses ONLY nix-darwin system.defaults options.
# ============================================================

{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # ACCESSIBILITY — POINTER APPEARANCE
  # ------------------------------------------------------------
  system.defaults.universalaccess = {

    # --- Cursor size --- #
    # ----------------------------------------------------------
    # Controls the visual size of the mouse pointer.
    #
    # mouseDriverCursorSize:
    #   1 = normal size
    #   4 = maximum size
    # ----------------------------------------------------------
    mouseDriverCursorSize = 2.0;
  };

  # ------------------------------------------------------------
  # GLOBAL PREFERENCES — MOUSE SPEED
  # ------------------------------------------------------------
  system.defaults.".GlobalPreferences" = {

    # --- Mouse tracking speed --- #
    # ----------------------------------------------------------
    # Controls how fast the pointer moves relative to mouse movement.
    #
    # Typical usable range:
    #   ~0.5 = very slow
    #   ~3.0 = very fast
    # ----------------------------------------------------------
    "com.apple.mouse.scaling" = 2.0;
  };

  # ------------------------------------------------------------
  # NSGlobalDomain — SCROLLING
  # ------------------------------------------------------------
  system.defaults.NSGlobalDomain = {

    # --- Scroll direction --- #
    # ----------------------------------------------------------
    # Controls whether scrolling uses “Natural” direction.
    #
    # true  = Natural scrolling
    #         (content follows finger movement, iOS-style)
    # false = Traditional scrolling
    #         (finger up = content up, Windows-style)
    # ----------------------------------------------------------
    "com.apple.swipescrolldirection" = false;
  };
}
