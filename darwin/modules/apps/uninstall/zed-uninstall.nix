# /Users/ven/iCloudDocs/dotfiles/nix/darwin/modules/apps/uninstall/zed-uninstall.nix
#
# ZED: SYSTEM UNINSTALL
# ============================================================
# This file makes sure Zed, which was installed through brew
# gets uninstalled, excluding its user-data.
# ============================================================

{ ... }:

{
  system.activationScripts.uninstallZed.text = ''
    set -euo pipefail
    echo "🧹 Removing Zed.app and its Homebrew cask..."

    if brew list --cask | grep -q "^zed$"; then
      brew uninstall --cask --force zed || true
    fi

    rm -rf "/Applications/Productivity/Zed.app"

    echo "Zed system bundle removed."
  '';
}
