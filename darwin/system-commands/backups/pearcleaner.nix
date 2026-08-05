# darwin/system-commands/backups/pearcleaner.nix
# Pearcleaner backup command: `pearcleaner-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  pearcleanerBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Pearcleaner";
    appSlug = "pearcleaner";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    sources = [
      { path = "/Users/ven/Library/Application Support/Pearcleaner"; destination = "Pearcleaner"; }
      { path = "/Users/ven/Library/Preferences/com.alienator88.Pearcleaner.plist"; destination = "app-pref/com.alienator88.Pearcleaner.plist"; }
      { path = "/Users/ven/Library/Preferences/group.com.alienator88.Pearcleaner.plist"; destination = "app-pref/group.com.alienator88.Pearcleaner.plist"; }
    ];
  };
in
pearcleanerBackup
