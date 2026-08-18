# darwin/system-commands/backups/yate.nix
# Yate backup command: `yate-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP PATHS
  applicationSupportEntries = [
    { relativePath = "Yate/Backups"; destinationPath = "app-support/Yate/Backups"; }
  ];
  preferenceEntries = [
    { relativePath = "com.2manyrobots.Yate.plist"; destinationPath = "app-pref/com.2manyrobots.Yate.plist"; }
  ];
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];
  additionalSources = [ ];

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 25;
  showProgress = true;
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "yate";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  yateBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Yate";
    appSlug = "yate";
    inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent showProgress;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
    inherit applicationSupportEntries preferenceEntries additionalSources extraExcludePatterns;
  };
in
yateBackup
