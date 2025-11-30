# /Users/ven/dotfiles/nix/darwin/modules/apps/uninstall/iterm-user-data-uninstall.nix
#
# iTerm2: UNINSTALL USER DATA
# ============================================================
# This module removes all iTerm2 user data managed by the
# iterm-symlinks.nix module.
#
# It removes:
#   - ~/Library/Application Support/iTerm2                 (symlink targets only)
#   - ~/Library/Preferences/com.googlecode.iterm2.plist   (symlink)
#   - ~/Library/Preferences/com.googlecode.iterm2.private.plist (symlink)
#   - /Users/ven/dotfiles/apps/iterm                      (real dotfiles)
#
# It does *not* remove:
#   - the iCloud backup folder:
#       ~/iCloudDocs/my-system/01-app_data/iterm
#
# Safe behavior:
#   - Both plist files become symlinks → deletion is safe
#   - Application Support/iTerm2 contains only symlinks → deletion is safe
#   - dotPath removal deletes only your local source-of-truth
# ============================================================

{ config, lib, pkgs, ... }:

let
  home    = config.home.homeDirectory;
  dotPath = "/Users/ven/dotfiles/apps/iterm";
in
{
  home.activation.uninstallItermUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Removing iTerm user data and symlinks…"

      # Remove the Application Support directory.
      rm -rf "${home}/Library/Application Support/iTerm2"

      # Remove primary and private plist files.
      rm -f "${home}/Library/Preferences/com.googlecode.iterm2.plist" \
            "${home}/Library/Preferences/com.googlecode.iterm2.private.plist"

      # Remove the dotfiles source-of-truth directory.
      rm -rf "${dotPath}"

      echo "✔ iTerm user data removed."
    '';
}
