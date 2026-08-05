# darwin/system-commands/backups/dash.nix
# Dash backup command: `dash-backup`.

{ lib, pkgs, ... }:

let
  dashBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "Dash";
    appSlug = "dash";
    sources = [
      { path = "/Users/ven/Library/Application Support/Dash"; destination = "app-support/Dash"; }
      { path = "/Users/ven/Library/Application Support/com.kapeli.dash-setapp"; destination = "app-support/com.kapeli.dash-setapp"; }
      { path = "/Users/ven/Library/Preferences/com.kapeli.dashdoc.plist"; destination = "app-pref/com.kapeli.dashdoc.plist"; }
      { path = "/Users/ven/Library/Preferences/com.kapeli.dash-setapp.plist"; destination = "app-pref/com.kapeli.dash-setapp.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ dashBackup ];
}
