# darwin/system-commands/backups/better-finder-renamer.nix
# A Better Finder Rename backup command: `better-renamer-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  betterRenamerBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "A Better Finder Rename";
    appSlug = "better-finder-renamer";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    commandName = "better-renamer-backup";
    sources = [
      { path = "/Users/ven/Library/Application Support/A Better Finder Rename 12"; destination = "A Better Finder Rename 12"; }
      { path = "/Users/ven/Library/Preferences/ABFR Registration"; destination = "app-pref/ABFR Registration"; }
      { path = "/Users/ven/Library/Preferences/net.publicspace.abfr12.plist"; destination = "app-pref/net.publicspace.abfr12.plist"; }
    ];
  };
in
betterRenamerBackup
