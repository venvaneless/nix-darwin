# iTerm2: UNINSTALL USER DATA
{ config, lib, pkgs, ... }:

let
  bundleId = "com.googlecode.iterm2";
  appCloud = "/Users/ven/dotfiles/apps/iterm";
in
{
  home.activation.cleanupIterm2Data = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    echo "Cleaning up iTerm2 support files and sync data..."

    rm -rf "$HOME/Library/Application Support/iTerm2" \
           "$HOME/Library/Preferences/${bundleId}.plist" \
           "${appCloud}"

    echo "iTerm2 user data removed."
  '';
}
