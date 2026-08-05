# darwin/system-commands/backups/pearcleaner.nix
# Pearcleaner backup command: `pearcleaner-backup`.

{ lib, pkgs, ... }:

let
  pearcleanerBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "Pearcleaner";
    appSlug = "pearcleaner";
    sources = [
      { path = "/Users/ven/Library/Application Support/Pearcleaner"; destination = "app-support/Pearcleaner"; }
      { path = "/Users/ven/Library/Preferences/com.alienator88.Pearcleaner.plist"; destination = "app-pref/com.alienator88.Pearcleaner.plist"; }
      { path = "/Users/ven/Library/Preferences/group.com.alienator88.Pearcleaner.plist"; destination = "app-pref/group.com.alienator88.Pearcleaner.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ pearcleanerBackup ];
}
