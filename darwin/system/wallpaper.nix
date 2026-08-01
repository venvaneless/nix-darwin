# /Users/ven/.config/nix/nix-config/darwin/modules/system/wallpaper.nix
# 
# =====================================================================
# WALLPAPER: SETTINGS
# =====================================================================

{ pkgs, ... }:

let
  # Set the wallpaper using AppleScript and a shell script
  setWallpaper = pkgs.writeShellScriptBin "set-wallpaper" ''
    #!/bin/bash
    set -euo pipefail

    # Wallpaper path
    WALLPAPER="/Users/ven/Pictures/wallpaper.jpg"

    echo "[INFO] Setting wallpaper to $WALLPAPER"

    # If the wallpaper file does not exist, exit with an error
    if [ ! -f "$WALLPAPER" ]; then
      echo "[ERROR] Wallpaper not found!"
      exit 1
    fi

    # Use AppleScript to set the wallpaper for all desktops
    /usr/bin/osascript <<EOF
    tell application "System Events"
      tell every desktop
        set picture to "$WALLPAPER"
      end tell
    end tell
    EOF

    echo "[SUCCESS] Wallpaper applied"
  '';
in
{
  environment.systemPackages = [ setWallpaper ];

  # Activation script to set the wallpaper on system activation
  system.activationScripts.setWallpaper.text = ''
    echo "[INFO] Running wallpaper setup..."
    ${setWallpaper}/bin/set-wallpaper
  '';
}
