# /Users/ven/dotfiles/nix/darwin/modules/apps/uninstall/chromium-uninstall.nix
#
# Chromium: UNINSTALL APPLICATION
# ============================================================
# This module removes the Chromium application bundle from your
# system.  It does *not* remove any configuration, plist, or
# Application Support files — those are handled separately in:
#
#   chromium-user-data-uninstall.nix
#
# This script is fully idempotent:
# - If Chromium.app does not exist → no error is thrown.
# - Both possible locations are removed:
#     /Applications/Chromium.app
#     /Applications/Programming/Chromium.app
#
# IMPORTANT:
#   This does *not* touch the iCloud backup folder in:
#     ~/iCloudDocs/my-system/01-app_data/chromium
# ============================================================

{ config, lib, pkgs, ... }:

{
  system.activationScripts.uninstallChromiumApp.text = ''
    set -euo pipefail
    echo "Removing Chromium application…"

    # Remove the app bundle from both expected installation locations.
    rm -rf "/Applications/Chromium.app" \
           "/Applications/Programming/Chromium.app"

    echo "✔ Chromium application removed."
  '';
}
