# darwin/system-commands/backups/dash.nix
# Dash backup command: `dash-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  dashBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Dash";
    appSlug = "dash";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    sources = [
      { path = "/Users/ven/Library/Application Support/Dash"; destination = "app-support/Dash"; }
      { path = "/Users/ven/Library/Application Support/com.kapeli.dash-setapp"; destination = "app-support/com.kapeli.dash-setapp"; }
      { path = "/Users/ven/Library/Preferences/com.kapeli.dashdoc.plist"; destination = "app-pref/com.kapeli.dashdoc.plist"; }
      { path = "/Users/ven/Library/Preferences/com.kapeli.dash-setapp.plist"; destination = "app-pref/com.kapeli.dash-setapp.plist"; }
    ];
  };
in
dashBackup
