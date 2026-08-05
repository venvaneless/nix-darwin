# darwin/system-commands/backups/vesktop.nix
# Vesktop backup command: `vesktop-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  vesktopBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Vesktop";
    appSlug = "vesktop";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    sources = [
      { path = "/Users/ven/Library/Application Support/vesktop"; destination = "vesktop"; }
      { path = "/Users/ven/Library/Preferences/dev.vencord.vesktop.plist"; destination = "dev.vencord.vesktop.plist"; }
    ];
  };
in
vesktopBackup
