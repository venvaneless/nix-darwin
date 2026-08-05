# darwin/system-commands/backups/better-finder-renamer.nix
# A Better Finder Rename backup command: `better-renamer-backup`.

{ lib, pkgs, ... }:

let
  betterRenamerBackup = import ./app-backup-helper.nix {
    inherit lib pkgs;
    appName = "A Better Finder Rename";
    appSlug = "better-finder-renamer";
    commandName = "better-renamer-backup";
    sources = [
      { path = "/Users/ven/Library/Application Support/A Better Finder Rename 12"; destination = "A Better Finder Rename 12"; }
      { path = "/Users/ven/Library/Preferences/ABFR Registration"; destination = "app-pref/ABFR Registration"; }
      { path = "/Users/ven/Library/Preferences/net.publicspace.abfr12.plist"; destination = "app-pref/net.publicspace.abfr12.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ betterRenamerBackup ];
}
