# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/mouse.nix
#
# MOUSE & POINTER SETTINGS
# ============================================================
# System-wide mouse and scrolling behavior.
#
# Covers:
# - Cursor size
# - Mouse speed
# - Natural scrolling
# - Tap behavior
#
# Uses ONLY nix-darwin system.defaults options.
# ============================================================

{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # ACCESSIBILITY — POINTER APPEARANCE
  # ------------------------------------------------------------
  system.defaults.universalaccess = {

    # Cursor size:
    # 1 = normal
    # 4 = maximum
    mouseDriverCursorSize = 2;
  };

  # ------------------------------------------------------------
  # NSGlobalDomain — MOUSE BEHAVIOR
  # ------------------------------------------------------------
  system.defaults.NSGlobalDomain = {

    # ----------------------------------------------------------
    # MOUSE SPEED / SCALING
    # ----------------------------------------------------------

    # Mouse tracking speed
    # Typical usable range: ~0.5 – 3.0
    "com.apple.mouse.scaling" = 2.0;

    # ----------------------------------------------------------
    # TAP BEHAVIOR
    # ----------------------------------------------------------

    # Tap behavior:
    # null = system default
    # 1    = enable tap-to-click
    "com.apple.mouse.tapBehavior" = null;

    # ----------------------------------------------------------
    # SCROLLING
    # ----------------------------------------------------------

    # Disable “Natural” scrolling direction
    # (content moves opposite to finger/mouse wheel)
    "com.apple.swipescrolldirection" = false;
  };
}
