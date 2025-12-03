# /Users/ven/dotfiles/nix/stable/darwin/modules/apps/uninstall/iterm-uninstall.nix
#
# iTerm2: UNINSTALL APPLICATION
# ============================================================
# Removes the iTerm application bundle.  This does *not* remove
# any user data, preferences, plists, or Application Support
# directories — those are handled in:
#
#   iterm-user-data-uninstall.nix
#
# iTerm may be installed in either:
#   /Applications/iTerm.app
#   /Applications/Programming/iTerm.app
#
# Both locations are removed safely and idempotently.
# ============================================================

{ config, lib, pkgs, ... }:

let
  appInProgramming  = "/Applications/Programming/iTerm.app";
  appInApplications = "/Applications/iTerm.app";
in
{
  system.activationScripts.uninstallItermApp.text = ''
    set -euo pipefail
    echo "Removing iTerm application…"

    # Remove both possible installation locations.  These commands
    # are safe even if the files do not exist.
    rm -rf "${appInProgramming}" \
           "${appInApplications}"

    echo "✔ iTerm application removed."
  '';
}
