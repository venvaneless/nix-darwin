# darwin/system-commands/backups/yate.nix
# Yate backup command: `yate-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  yateBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Yate";
    appSlug = "yate";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    sources = [
      { path = "/Users/ven/Library/Application Support/Yate/Backups"; destination = "Backups"; }
      { path = "/Users/ven/Library/Preferences/com.2manyrobots.Yate.plist"; destination = "com.2manyrobots.Yate.plist"; }
    ];
  };
in
yateBackup
