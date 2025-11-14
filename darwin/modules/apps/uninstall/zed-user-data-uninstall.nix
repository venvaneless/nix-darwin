# /Users/ven/dotfiles/nix/darwin/modules/apps/uninstall/zed-user-data-uninstall.nix

# ZED: UNINSTALL USER DATA
# =========================

{ config, lib, pkgs, ... }:

let
  bundleId = "dev.zed.Zed";
  appCloud = "/Users/ven/dotfiles/apps/zed"; # or your new non-iCloud path
in
{
  home.activation.cleanupZedData = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    echo "Cleaning up Zed support files and sync data..."

    rm -rf "$HOME/Library/Application Support/Zed" \
           "$HOME/Library/Preferences/${bundleId}.plist" \
           "${appCloud}"

    echo "Zed user data removed."
  '';
}
