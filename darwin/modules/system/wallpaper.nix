# /Users/ven/.config/nix/nix-config/darwin/modules/system/wallpaper.nix
# 
# =====================================================================
# WALLPAPER: SETTINGS
# =====================================================================

{ pkgs, ... }:

let
  setWallpaper = pkgs.writeShellScriptBin "set-wallpaper" ''
    #!/bin/bash
    set -euo pipefail

    WALLPAPER="/Users/ven/Pictures/wallpaper.jpg"

    echo "[INFO] Setting wallpaper to $WALLPAPER"

    if [ ! -f "$WALLPAPER" ]; then
      echo "[ERROR] Wallpaper not found!"
      exit 1
    fi

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

  # DARWIN: ACTIVATION SCRIPT
  system.activationScripts.setWallpaper.text = ''
    echo "[INFO] Running wallpaper setup..."
    ${setWallpaper}/bin/set-wallpaper
  '';
}
