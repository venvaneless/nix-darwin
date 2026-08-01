# /Users/ven/.config/nix/nix-config/darwin/modules/system/screenshot-options.nix
#
# =====================================================================
# SCREENSHOT OPTIONS
# 
# Global screenshot behavior for macOS.
# =====================================================================

{ config, lib, pkgs, ... }:

{
  system.defaults.screencapture = {

  	# ****************************************************************
    # ------ FILE FORMAT & NAMING ------ #
    # ****************************************************************
    
    # Include date in filename
    include-date = true;

    # Screenshot file type: png, jpg, pdf, tiff
    type = "png";
    # ****************************************************************

    
    # ****************************************************************
    # ------ UI BEHAVIOR ------ #
    # ****************************************************************

    # Disable screenshot shadow
    disable-shadow = true;

    # Show floating thumbnail after capture
    show-thumbnail = true;
    # ****************************************************************


    # ****************************************************************
    # ------ LOCATION ------ #
    # Default save location
    # ****************************************************************

    location = "/Users/ven/iCloudDocs/Downloads";
    # ****************************************************************

  };
}
