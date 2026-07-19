# /Users/ven/.config/nix/nix-config/darwin/modules/system/dock-options.nix
# 
# =====================================================================
# DOCK OPTIONS
# 
# Dock defaults configured via nix-darwin.
# - Sets size, autohide behaviour, orientation and animations.
# - Enables icon magnification on hover.
# - Provides placeholders for all other Dock-related options.
# =====================================================================

{ config, lib, pkgs, ... }:

{
	# ---------------------------------------------------------------
  # ------ DOCK CORE SETTINGS ------ #
  # Dock size, position, visibility and animations
  # Uses: system.defaults.dock.* from nix-darwin
  # ---------------------------------------------------------------

  system.defaults.dock = {
  
    # ------ SIZE AND MAGNIFICATION ------ #

    # --- Icon size in pixels
    tilesize = 72;
    # **************************************


    # --- Magnify icons on hover
    magnification = true;
    # **************************************


    # --- Magnified icon size when hovering
    largesize = 80;
    # **************************************

    # --- Hide/show the Dock
    autohide = true;
    # autohide-delay = 0.0;
    # autohide-time-modifier = 0.5;
    # **************************************

    # **************************************
    # ------ POSITION ------ #

    # --- Dock position
    # :contentReference[oaicite:1]{index=1}
    orientation = "bottom";
    # **************************************

    # **************************************
    # --- Animate opening applications
    launchanim = false;
    # **************************************
    
    # **************************************
    # --- Minimize/maximize effect
    # Options: "genie", "scale", or "suck"
    mineffect = "scale";
    # **************************************

    # **************************************
    # --- Minimize windows into
    # their application icon
    # 
    # ... instead of separate tile
    # --------------------------------------
    minimize-to-application = false;
    # **************************************

    # **************************************
    # --- Indicator lights for open applications
    show-process-indicators = true;
    # **************************************

    # **************************************
    # --- Show recent applications in the Dock
    show-recents = true;
    # **************************************

    # **************************************
    # --- Make icons of hidden applications translucent
    showhidden = true;
    # **************************************


    # ------ MISCELLANEOUS ------ #
    #
    # --- Dragging files through folders
    enable-spring-load-actions-on-all-items = true;
    
   	# -------------------------------------------------
    # ------ OTHER - DISABLED ------ #
    # -------------------------------------------------
    
    # **************************************
    # ------ HOT CORNERS ------ #
    # wvous-bl-corner = 1; # bottom-left
    # wvous-br-corner = 1; # bottom-right
    # wvous-tl-corner = 1; # top-left
    # wvous-tr-corner = 1; # top-right
    # **************************************

    # ********************************************************
    # ---- Mission Control animation duration
    # 
    # Changes the Mission Control animation duration (Exposé-style animation).
    # Lower value → faster animation
    # Higher value → slower animation
    # ********************************************************
    # expose-animation-duration = 0.25;
    
    # ********************************************************
    # --- Toggles grouping of windows by application
    # ... when entering Mission Control / App Exposé.
    # 
    # ON = Windows grouped by app
    # OFF = All windows shown individually
    # ********************************************************
    expose-group-apps = true;

    # ********************************************************
    # ---- Highlight stack when hovering
    # When hovering over a “stack” (Downloads folder, etc.) in the Dock, the hovered item becomes highlighted
    # 
    # ON = Highlight on hover
    # OFF = No highlight
    # ********************************************************
    mouse-over-hilite-stack = true;
    
    # ********************************************************
    # --- Most Recently Used Spaces
    # ON = macOS will automatically reorder your Spaces based on your usage.
    # OFF = Spaces stay exactly where you placed them.
    # ********************************************************
    # mru-spaces = false;

    # ********************************************************
    # ---- Scroll to open app in Dock
    # Allows scrolling (trackpad scroll gesture) upward
    # on a Dock icon to activate Exposé for that app.
    # Scroll up on Safari icon → shows all Safari windows.
    # ********************************************************
    scroll-to-open = true;

    # ********************************************************
    # --- Slow Motion while minimising
    # Hold Shift while minimizing or opening apps to play the slow-motion
    # ********************************************************
    # slow-motion-allowed = true;

    # --- Dynamic Dock behaviour
    static-only = false;

  # ********************************************************
    persistent-apps = [
    "/Applications/LocalSend.app"
    "/Applications/Multimedia/Cider.app"
    "/Applications/Programming/WezTerm.app"
    "/Applications/Helium.app"
    "/Applications/LibreWolf.app"
    "/Applications/Productivity/Zed.app"
    "/Applications/Programming/SnippetsLab.app"
    "/Applications/ChatGPT Classic.app"
    ];
  # ********************************************************
  };
}
