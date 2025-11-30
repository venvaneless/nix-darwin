# /Users/ven/dotfiles/nix/darwin/modules/apps/uninstall/chromium-user-data-uninstall.nix
#
# Chromium: UNINSTALL USER DATA
# ============================================================
# This module removes all Chromium support files that were
# managed by chromium-symlinks.nix.
#
# It removes:
#   - ~/Library/Application Support/Chromium     (symlink targets only)
#   - ~/Library/Preferences/org.chromium.Chromium.plist (symlink)
#   - /Users/ven/dotfiles/apps/chromium          (real source-of-truth data)
#
# It does *not* remove:
#   - the iCloud backup folder:
#       ~/iCloudDocs/my-system/01-app_data/chromium
#
# Safe behavior:
#   - Application Support/Chromium is symlink-only → safe to delete
#   - Preferences plist is a symlink → safe to delete
#   - dotfiles folder removal is expected behavior
# ============================================================

{ config, lib, pkgs, ... }:

let
  home    = config.home.homeDirectory;
  dotPath = "/Users/ven/dotfiles/apps/chromium";
in
{
  home.activation.uninstallChromiumUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Removing Chromium user data and symlinks…"

      # Remove the runtime Application Support directory.
      rm -rf "${home}/Library/Application Support/Chromium"

      # Remove the symlinked preferences plist.
      rm -f "${home}/Library/Preferences/org.chromium.Chromium.plist"

      # Remove the dotfiles source-of-truth directory.
      rm -rf "${dotPath}"

      echo "✔ Chromium user data removed."
    '';
}
